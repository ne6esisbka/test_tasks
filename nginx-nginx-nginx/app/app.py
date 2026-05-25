from http.server import HTTPServer, BaseHTTPRequestHandler

class RequestHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-type', 'text/plain; charset=utf-8')
        self.end_headers()
        
        # Получаем заголовок X-Forwarded-For из запроса
        xff = self.headers.get('X-Forwarded-For', 'Заголовок отсутствует')
        
        response = f"Полученный X-Forwarded-For: {xff}\n"
        self.wfile.write(response.encode('utf-8'))

if __name__ == '__main__':
    server = HTTPServer(('0.0.0.0', 8000), RequestHandler)
    print("Сервер запущен на порту 8000...")
    server.serve_forever()