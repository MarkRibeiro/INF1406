use std::collections::HashMap;
use regex::Regex;
use std::thread;
use std::net::{TcpListener, TcpStream};
use std::io::Read;
use std::io::Write;
use std::process;
use std::sync::mpsc;
use std::sync::mpsc::Sender;
use std::env::args;

fn main() {
  let arg_lis = args().collect::<Vec<String>>();
  let id: i32 = arg_lis[1].parse().unwrap();
  let tot: i32 = arg_lis[2].parse().unwrap();
  let listener = TcpListener::bind("127.0.0.1:7878").unwrap();
  println!("vai esperar conexoes!");

  let (send_channel, receive_channel) = mpsc::channel();
  let send_channel: Sender<(String, String, Option<String>)> = send_channel;
  thread::spawn(move || {
    let mut dicionario: HashMap<String, String> = HashMap::new();
    loop {
      let (behavior, key, value) = receive_channel.recv().unwrap();
      println!("behavior: {:?}", &behavior);
      println!("key: {:?}", &key);
      println!("value: {:?}", &value);
      let mut ret: String = "OK".to_string();
      let mut hash: i32 = 0;
      for byte in key.as_bytes() {
        hash += (*byte) as i32;
      }
      hash = hash % tot;

      if (hash == id) {
        if behavior == "I" {
          insere(key, value.unwrap(), &mut dicionario);
        } else if behavior == "C" {
          ret = consulta(key, &mut dicionario);
        }

        if let Ok(mut stream) = TcpStream::connect("127.0.0.1:7879") {
          let bufsend = ret.as_bytes();

          let res = stream.write(bufsend);
          match res {
            Ok(num) => println!("Enviou {}", String::from_utf8_lossy(&bufsend[..num])),
            Err(_) => {
              println!("erro na escrita");
              process::exit(0x0)
            }
          }
        } else {
          println!("não consegui me conectar...");
        }
      } else {
        unimplemented!("ROTEAMENTO");
      }
    }
  });

  for stream in listener.incoming() {
    let stream = stream.unwrap();
    println!("nova conexão!");
    let send_clone = send_channel.clone();
    thread::spawn(move || {
      tratacon(stream, send_clone)
    });
  }
}

fn interpreta_mensagem(msg: String, send: Sender<(String, String, Option<String>)>) {
  let re = Regex::new(r"(?P<behavior>I|C)\+(?P<key>[^\+]+)\+(?:(?P<value>[^\+]+)\+)?").unwrap();
  let caps = re.captures(&msg).unwrap();
  let behavior = caps.name("behavior").unwrap().as_str();
  let key = caps.name("key").unwrap().as_str();
  let value;
  match caps.name("value") {
    None => value = None,
    Some(value2) => value = Some(value2.as_str().to_string())
  }
  send.send((behavior.to_string(), key.to_string(), value));
}

fn tratacon(mut s: TcpStream, send: Sender<(String, String, Option<String>)>) {
  let mut buffer = [0; 128];
  let res = s.read(&mut buffer);

  let lidos = match res {
    Ok(num) => num,
    Err(_) => {
      println!("erro");
      process::exit(0x01)
    }
  };

  let st = String::from_utf8_lossy(&buffer[..lidos]);

  println!("recebeu: {}", st);

  let msg = st.to_string();
  interpreta_mensagem(msg, send);
}

fn insere(key: String, value: String, dicionario: &mut HashMap<String, String>) {
  dicionario.insert(key, value);
}

fn consulta(key: String, dicionario: &mut HashMap<String, String>) -> String {
  return dicionario.get(&*key).unwrap().clone();
}