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

    header_row = ["filename","type","value","score"]

    CSV.open(output, "wb") do |csv|
      csv << header_row

      input_data = CSV.read(input, { encoding: "UTF-8", headers: true, header_converters: :symbol, converters: :all}).map { |d| d.to_hash }
      total = input_data.size

      puts "#{total} files in input file"
      input_data.each_with_index do |row, i|
        filename = row[:filename]
        full_path = File.join(base_path,filename)

        puts "...#{i+1} of #{total}: #{filename}"

        if File.exists?(full_path)

          begin

            response = vision.image(full_path)

            response.labels.each { |label| csv << [filename, "label", label.description, label.score.round(2)] }
            response.web.entities.each { |entity| csv << [filename, "entity", entity.description, entity.score.round(2)] }

            ocr_response = response.text # nope, not a typo, text is the part of the response that has OCR info, and text is the attribute with the actual OCRed text
            ocr_text = ocr_response ? ocr_response.text.gsub(/\n/," ") : ""
            csv << [filename, "ocr", ocr_text, ""]

          rescue StandardError => e

            puts "***ERROR: exception #{e.message} for #{filename}!"

          end

        else

          puts "***ERROR: file #{filename} not found!"

        end

      end

    end
    end_time = Time.now
    puts "ended at #{end_time}"
    puts "Total run time = #{((end_time - start_time)/60.0).round(1)} minutes"
    puts "Output file: #{output}"

  end

end
