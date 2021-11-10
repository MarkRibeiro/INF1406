use std::net::{TcpListener, TcpStream};
use std::io::Write;
use std::io::Read;
use std::{io, process};

fn main () {
  let mut myPort =  String::new();
  io::stdin().read_line(&mut myPort);
  myPort = myPort.trim().parse().unwrap();
  let myIp = format!("127.0.0.1:{}",myPort);
  loop {
    let mut nodeString =  String::new();
    io::stdin().read_line(&mut nodeString);
    let nodeNumber : i32 = nodeString.trim().parse().unwrap();

    if let Ok(mut stream) = TcpStream::connect("127.0.0.1:".to_string()+(7879 + nodeNumber).to_string().as_str()) {
      println!("me conectei com o servidor!");
      let mut buffer = String::new();

      io::stdin().read_line(&mut buffer);
      let bufsend;

      bufsend = format!("{}+{}",myIp.clone(),buffer.trim());

      let res = stream.write(bufsend.as_bytes());
      match res {
        Ok(num) => println!("Enviou {}", String::from_utf8_lossy(&bufsend.as_bytes())),
        Err(_) => {
          println!("erro na escrita");
          process::exit(0x0)
        },
      }

      let listener = TcpListener::bind(myIp.clone()).unwrap();
      for stream in listener.incoming() {
        let mut stream = stream.unwrap();
        let mut bufrec: [u8; 128] = [0; 128];
        let aux = stream.read(&mut bufrec);
        println!("recebi de volta: {}", String::from_utf8_lossy(&bufrec[..aux.unwrap()]));
        break;
      }
    } else {
      println!("não consegui me conectar...");
    }
  }
}