task :start do
  system 'redis-server &'
  system 'bundle exec foreman start -f Procfile_development'
end

desc "Create stolen tsv"
task :create_stolen_tsv => :environment do
  out_file = File.join(Rails.root,'/current_stolen_bikes.tsv')
  headers = "Make\tModel\tSerial\tDescription\tArticleOrGun\tDateOfTheft\tCaseNumber\tLEName\tLEContact\tComments\n"
  output = File.open(out_file, "w")
  output.puts headers
  StolenRecord.where(current: true).where(approved: true).includes(:bike).each do |sr|
    output.puts sr.tsv_row if sr.tsv_row.present?
  end
  output
  
  uploader = TsvUploader.new
  uploader.store!(output)
  output.close
  puts uploader.url
end
