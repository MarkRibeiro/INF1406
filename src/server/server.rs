use regex::Regex;
use std::thread;
use std::net::{TcpListener, TcpStream};
use std::io::Read;
use std::io::Write;
use std::process;
use std::sync::mpsc;
use std::sync::mpsc::Sender;

fn interpreta_mensagem (msg: String, send: Sender<(String, String, Option<String>)>) {
  let re = Regex::new(r"(?P<behavior>I|C)\+(?P<key>[^\+]+)\+(?:(?P<value>[^\+]+)\+)?").unwrap();
  let caps = re.captures(&msg).unwrap();
  let behavior = caps.name("behavior").unwrap().as_str();
  let key = caps.name("key").unwrap().as_str();
  let value;
  match caps.name("value"){
    None => value = None,
    Some(value2) => value = Some(value2.as_str().to_string())
  }

  send.send((behavior.to_string(), key.to_string(), value));
}

fn tratacon (mut s: TcpStream, send: Sender<(String, String, Option<String>)>) {

  let mut buffer = [0; 128];
  let res = s.read(&mut buffer);

  let lidos = match res {
    Ok(num) => num,
    Err(_) => {println!("erro"); process::exit(0x01)},
  };

  println!("recebi {} bytes", lidos);

  let st = String::from_utf8_lossy(&buffer);

  println!("recebeu: {}", st);

  let msg = st.to_string();
  interpreta_mensagem(msg, send);

  let res = s.write(&buffer[0..lidos]);
  match res {
    Ok(num) => println!("escreveu {}", num),
    Err(_) => {println!("erro"); process::exit(0x01)},
  }

}

fn main() {
  let listener = TcpListener::bind("127.0.0.1:7878").unwrap();
  println! ("vai esperar conexoes!");

  let (send_channel, receive_channel) = mpsc::channel();
  thread::spawn(move || {
    loop {
      let (behavior, key, value) = receive_channel.recv().unwrap();
      println!("{:?}", behavior);
      println!("{:?}", key);
      println!("{:?}", value);
      println!("oi eu so 1 thread");
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