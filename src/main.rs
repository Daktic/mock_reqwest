use std::env;
use actix_web::{get, post, App, HttpServer, HttpResponse, Responder};


// Handler for the GET request
#[get("/get")]
async fn get_handler() -> impl Responder {
    HttpResponse::Ok().body("Hello, this is a GET request!")
}

// Handler for the POST request
#[post("/post")]
async fn post_handler() -> impl Responder {

    let client = reqwest::Client::new(); // Causes Segfault

    HttpResponse::Ok().body("Hello, this is a POST request!")
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {

    let port:u16 = env::var("PORT").unwrap_or("8080".to_string()).parse().unwrap();
    // Create Actix-web App with routes
    HttpServer::new(|| {
        App::new()
            // Define GET route
            .service(get_handler)
            // Define POST route
            .service(post_handler)
    })
        .bind(("0.0.0.0", port))?
        .run()
        .await
}