import requests
import sys
print(sys.argv)
time = sys.argv[1]
matricula = sys.argv[2] 

class GerenteDeRequest():
    def __init__(this,time, matricula):
      this.time = time
      this.matricula = matricula
    def preparaRequest(this,data):
        url = "https://docs.google.com/forms/d/e/1FAIpQLSe-iUYNWdLQjHjOTv6WYh6hXk2DpmTTYq87QEvi_VjIuL1HAA/formResponse"
        s = requests.Session()
        ret = this.enviaRequest(s,url,data)
        return ret 
    def enviaRequest(this,s,url, data):
        print(data)
        result = s.post(url, data)
        if( result.status_code != 200):
            print("Valores possivelmente invalidos, insira novamente.")
            return False
        else:
            print("ok")
            return True

    def preencheData(this):
        data = {
                    "entry.786316967" : this.time,
                    "entry.2111961315": this.matricula
        }
        return data
gerente  = GerenteDeRequest(time,matricula)
data = gerente.preencheData()
gerente.preparaRequest(data)

