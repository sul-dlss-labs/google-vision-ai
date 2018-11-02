if Rails.env == "production"
  ENV['GOOGLE_APPLICATION_CREDENTIALS'] = './google_application_credentials.json'
  File.open("./google_application_credentials.json", "w+") do |f|
    f.write(ERB.new(File.read('./google_application_credentials.json.tmp')).result)
  end
end

PROJECT_ID = "sul-ai-studio" # Your Google Cloud Platform project ID
