require 'csv'
require 'google/apis/civicinfo_v2'

# From google api documentation:
civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
# A registered API Key to authenticate our requests
civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

def clean_zipcode (zipcode)
  # if the zip code is exactly five digits, assume that it is ok
  # if the zip code is more than five digits, truncate it to the first five digits
  # if the zip code is less than five digits, add zeros to the front until it becomes five digits
  zipcode.to_s.rjust(5, '0')[0..4]
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

  begin
    legislators = civic_info.representative_info_by_address(
      address: zipcode,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    )
    legislators = legislators.officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end

  puts "#{name} #{zipcode} #{legislators}"
end
