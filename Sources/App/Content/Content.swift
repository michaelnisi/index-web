import Foundation

struct HTMLPartial {
    let html: String
    let date: Date
}

struct LinkedData {
    let string = """
    {
      "@context": "https://schema.org",
      "@type": "WebSite",
      "name": "Michael Nisi",
      "url": "https://michaelnisi.com",
      "publisher": {
        "@type": "Person",
        "name": "Michael Nisi"
      }
    }
    """
}
