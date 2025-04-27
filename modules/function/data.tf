data "http" "zip_file" {
  url = local.func_zip_url

  request_headers = {
    Accept = "application/zip"
  }

  lifecycle {
    postcondition {
      condition     = contains([200], self.status_code)
      error_message = "Status code invalid - ${self.status_code}"
    }
  }
}

resource "local_sensitive_file" "zip_file" {
  content_base64 = data.http.zip_file.response_body_base64
  filename = local.zip_file_path
}