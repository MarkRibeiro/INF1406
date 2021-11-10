use std::collections::{HashMap, LinkedList};
use regex::Regex;
use std::thread;
use std::net::{TcpListener, TcpStream};
use std::io::Read;
use std::io::Write;
use std::process;
use std::sync::mpsc;
use std::sync::mpsc::Sender;
use std::env::args;

type Request = (String, String, String, Option<String>, String) ;
fn main() {
  let arg_lis = args().collect::<Vec<String>>();
  let id: i32 = arg_lis[1].parse().unwrap();
  let total: i32 = arg_lis[2].parse().unwrap();
  let mut delayed_requests : LinkedList<Request> = LinkedList::new();
  let listener = TcpListener::bind("127.0.0.1:".to_owned()+ (7879 + id).to_string().as_str()).unwrap();
  println!("vai esperar conexoes!");

  let (send_channel, receive_channel) = mpsc::channel();
  let send_channel: Sender<Request> = send_channel;
  thread::spawn(move || {
    let mut dicionario: HashMap<String, String> = HashMap::new();
    let mut rotas: HashMap<i32, String> = HashMap::new();
    for i in 0..total {
      if i == id {
        continue
      }
      else {
        let next: i32 = route(id, i, total);
        rotas.insert(i, (7879 + next).to_string());
      }
    }
    loop {
      let mut requests : LinkedList<Request> = delayed_requests.clone();
      requests.push_front(receive_channel.recv().expect("Error receiving message"));
      for msg in requests {
        let (IP, behavior, key, value, message) = msg;
        println!("IP: {:?}", &IP);
        println!("behavior: {:?}", &behavior);
        println!("key: {:?}", &key);
        println!("value: {:?}", &value);
        let mut ret: String = "OK".to_string();
        let mut hash: i32 = 0;
        for byte in key.as_bytes() {
          hash += (*byte) as i32;
        }
        hash = hash % total;

        if hash == id {
          if behavior == "I" {
            insere(key, value.unwrap(), &mut dicionario);
          } else if behavior == "C" {
            let dict_val = consulta(key.clone(), &mut dicionario);
            match dict_val {
              None => {
                delayed_requests.push_back((IP, behavior, key, value, message));
                continue;
              }
              Some(val) => { ret = val.clone(); }
            }
          }

          if let Ok(mut stream) = TcpStream::connect(IP) {
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
          if let Ok(mut stream) = TcpStream::connect("127.0.0.1:".to_owned() + (rotas.get(&hash).unwrap()).as_str()) {
            let bufsend: &[u8] = message.as_bytes();

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
        }
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

fn interpreta_mensagem(msg: String, send: Sender<Request>) {
  let re = Regex::new(r"(?P<IP>[^\+]+)\+(?P<behavior>I|C)\+(?P<key>[^\+]+)\+(?:(?P<value>[^\+]+)\+)?").unwrap();
  let caps = re.captures(&msg).unwrap();
  let IP = caps.name("IP").unwrap().as_str();
  let behavior = caps.name("behavior").unwrap().as_str();
  let key = caps.name("key").unwrap().as_str();
  let value;
  match caps.name("value") {
    None => value = None,
    Some(value2) => value = Some(value2.as_str().to_string())
  }
  send.send((IP.to_string(), behavior.to_string(), key.to_string(), value, msg));
}

fn tratacon(mut s: TcpStream, send: Sender<Request>) {
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

fn route(from: i32, to: i32, total: i32) -> i32 {
  if from != 0 {
    return (route(0,(to - from).rem_euclid(total),total)+from).rem_euclid(total)
  } else {
    return 2_i32.pow(f32::floor(f32::log2(to as f32)) as u32) as i32;
  }
}

fn insere(key: String, value: String, dicionario: &mut HashMap<String, String>) {
  dicionario.insert(key, value);
}

fn consulta(key: String, dicionario: &mut HashMap<String, String>) -> Option<&String> {
  return dicionario.get(&*key).clone();
}