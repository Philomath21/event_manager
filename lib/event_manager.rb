require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zipcode (zipcode)
  # if the zip code is exactly five digits, assume that it is ok
  # if the zip code is more than five digits, truncate it to the first five digits
  # if the zip code is less than five digits, add zeros to the front until it becomes five digits
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone(phone)
  phone = phone.split('').select { |digit| digit.match?(/^[0-9]$/) }.join
  phone.size == 10 || phone.size == 11 && phone[0] == "1" ? phone[-10..] : "Bad number"
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
    ).officials
    legislators
    # returns an array of legislators
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def time_to_hour_or_day(reg_time, ddd_or_hh)
  ddd_or_hh == "h" ? reg_time.strftime("%H") : reg_time.strftime("%A")
end

# para (parameter) can be hour or day, ddd_or_hh can be accordingly "h" or "d"
def peak_reg_time(reg_times_a, ddd_or_hh)
  freq_hash = Hash.new(0) # hour/day => freq
  reg_times_a.each do |reg_time|
    freq_hash[time_to_hour_or_day(reg_time, ddd_or_hh)] += 1
  end

  peak_freq = freq_hash.values.max
  peak_para_a = []

  freq_hash.each do |para, freq|
    peak_para_a.push(para) if freq == peak_freq
  end
  peak_para_a
end
reg_times_a = []

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')
  filename = "output/thanks_#{id}.html"
  File.open(filename, 'w') { |file| file.puts form_letter }
end

puts 'Event Manager Initialized!'

# CSV#open Opens file as a CSV object (CSV is a class in ruby)
contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  phone = clean_phone(row[:homephone])
  legislators = legislators_by_zipcode(zipcode)
  form_letter = erb_template.result(binding)

  save_thank_you_letter(id,form_letter)
  reg_times_a.push(Time.strptime(row[:regdate], "%m/%d/%y %k:%M"))
end

puts "Peak registration hour: #{peak_reg_time(reg_times_a, "h").join(", ")}"
puts "Peak registration day: #{peak_reg_time(reg_times_a, "d").join(", ")}"
