require 'csv'
require 'google/apis/civicinfo_v2'

def clean_zipcode (zipcode)
  # if the zip code is exactly five digits, assume that it is ok
  # if the zip code is more than five digits, truncate it to the first five digits
  # if the zip code is less than five digits, add zeros to the front until it becomes five digits
  zipcode.to_s.rjust(5, '0')[0..4]
end

def legislators_by_zipcode (zipcode)
  # From google api documentation:
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  # A registered API Key to authenticate our requests
  civic_info.key = File.read('secret.key').strip

  begin
    legislators = civic_info.representative_info_by_address(
      address: zipcode,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    )
    legislators = legislators.officials
    legislator_names = legislators.map {|legislator| legislator.name}
    return legislator_names.join(', ')
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

puts 'Event Manager Initialized!'

# CSV#open Opens file as a CSV object (CSV is a class in ruby)
contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

contents.each do |row|
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)

  puts "#{name} #{zipcode} #{legislators}"
end
