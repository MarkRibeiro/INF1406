use std::net::{TcpListener, TcpStream};
use std::io::Write;
use std::io::Read;
use std::{io, process};

fn main () {
  let mut my_port =  String::new();
  println!("Entre com a porta:");
  let res = io::stdin().read_line(&mut my_port);
  match res {
    Ok(_) => {}
    Err(_) => { println!("erro na leitura");
      process::exit(0x0)}
  }
  my_port = my_port.trim().parse().unwrap();
  let my_ip = format!("127.0.0.1:{}", my_port);
  loop {
    let mut node_string =  String::new();
    println!("Entre com o nó de partida:");
    let res = io::stdin().read_line(&mut node_string);
    match res {
      Ok(_) => {}
      Err(_) => { println!("erro na leitura");
        process::exit(0x0)}
    }
    let node_number: i32 = node_string.trim().parse().unwrap();

    if let Ok(mut stream) = TcpStream::connect("127.0.0.1:".to_string()+(7879 + node_number).to_string().as_str()) {
      println!("me conectei com o servidor!");
      let mut buffer = String::new();
      println!("Entre com a consulta (<C|I>+<chave>[+<valor>]+):");
      let res = io::stdin().read_line(&mut buffer);
      match res {
        Ok(_) => {}
        Err(_) => { println!("erro na leitura");
          process::exit(0x0)}
      }
      let bufsend;

      bufsend = format!("{}+{}", my_ip.clone(), buffer.trim());

      let res = stream.write(bufsend.as_bytes());
      match res {
        Ok(_num) => println!("Enviou {}", String::from_utf8_lossy(&bufsend.as_bytes())),
        Err(_) => {
          println!("erro na escrita");
          process::exit(0x0)
        },
      }

      let listener = TcpListener::bind(my_ip.clone()).unwrap();
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