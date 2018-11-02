require 'csv'

namespace :vision do

  desc "Batch run images through Google Vision API given a image base path, an input file with image locations and output location"
  #Run Me: bundle exec rake vision:batch_run['/dor/staging', '~/input.csv', '~/output.csv']
  # arguments are: (1) image base path, (2) input file location, (3) output file location
  # input file format is plain text with a single column containing filenames -- no header row
  #  each filename will be prepended by the base path passed in and run through the google vision API, with results
  #  saved in the output file specified
  task :batch_run, [:base_path, :input, :output]  => :environment do |t, args|
    base_path = args[:base_path]
    input = args[:input]
    output = args[:output]
    puts "Google Vision API Batch Run"
    start_time = Time.now
    puts "started at #{start_time}"
    puts "Image Base path: #{base_path}"
    puts "Input file: #{input}"
    puts "Output file: #{output}"

    raise "input file not found" unless File.exists?(input)

    vision = Google::Cloud::Vision.new project: PROJECT_ID

    header_row = ["filename","labels","label_scores","entities","entity_scores"]
    #Setup the output csv
    CSV.open(output, "wb") do |csv|
      #Write Out The Headers
      csv << header_row

      filenames = CSV.read(input)
      total = filenames.size
      puts "#{total} files in input file"
      filenames.each_with_index do |row, i|
        filename = row[0]
        full_path = File.join(base_path,filename)
        puts "...#{i+1} of #{total}: #{filename}"

        response = vision.image(full_path)
        label_response = response.labels
        entity_response = response.web.entities

        labels = label_response.map { |label| label.description }.join(', ')
        label_scores = label_response.map { |label| label.score.round(2) }.join(', ')

        entities = entity_response.map { |entity| entity.description }.join(', ')
        entity_scores = entity_response.map { |entity| entity.score.round(2) }.join(', ')

        csv << [filename, labels, label_scores, entities, entity_scores]
      end

    end
    end_time = Time.now
    puts "ended at #{end_time}"
    puts "Total run time = #{((end_time - start_time)/60.0).round(1)} minutes"
    puts "Output file: #{output}"

  end

end
