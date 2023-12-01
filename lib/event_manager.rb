require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def clean_phone_number(phone)
    if phone.length > 10
        nil
    elsif phone.length == 11 && phone[0] == "1"
        phone[1..-1]
    elsif phone.length == 11 && phone[0] != "1"
        nil
    elsif phone.length > 11
        nil
    else
        phone
    end
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter
hours = Array.new(24, 0)
days = Array.new(7, 0)
wdays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
contents.each do |row|
  id = row[0]
  name = row[:first_name]
  date = row[1]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)
  parsed_date = DateTime.strptime(date, '%m/%d/%y %H:%M')
  hour = parsed_date.hour
  day = parsed_date.wday
  days[day] += 1
  hours[hour] += 1
  save_thank_you_letter(id,form_letter)
end

max_value = hours.max
max_indices = []

hours.each_with_index do |value, index|
  max_indices << index if value == max_value
end

puts "The most accessed hour was #{max_indices.join(', ')} with #{max_value} hits."

max_value = days.max
max_index = days.each_with_index.max[1]

puts "The most accessed day was #{wdays[max_index]} with #{max_value} hits."


