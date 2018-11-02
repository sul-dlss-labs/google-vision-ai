class ImageController < ApplicationController

  def index

  end

  def results

    input_value = params[:input_value].strip.downcase

    druid_match = /[a-zA-Z]{2}[0-9]{3}[a-zA-Z]{2}[0-9]{4}/.match(input_value)

    if druid_match.nil?

      @error = "The value entered was not a valid druid or PURL"
      return false

    end

    @druid = druid_match.to_s

    iiif_manifest_url = "https://purl.stanford.edu/#{@druid}/iiif/manifest"

    begin

      client = IiifGoogleCv::Client.new(manifest_url: iiif_manifest_url)
      images = client.image_resources

      @results = []
      vision = Google::Cloud::Vision.new project: PROJECT_ID
      images.each do |image|
        response = vision.image(image)
        labels = response.labels.map { |label| {description: label.description, score: label.score} }
        entities = response.web.entities.map { |entity| {description: entity.description, score: entity.score} }
        @results << {image: image, labels: labels, entities: entities}
      end

    rescue Google::Cloud::InvalidArgumentError => e

      @error = "Google returned an error: \"#{e.message}\".  Its likely this image is restricted in some way (either not viewable at all or only as a thumbnail)"

    rescue StandardError => e

      @error = "Something bad happened and we don't know what. This might help: \"#{e.message}\"."

    end

  end

end
