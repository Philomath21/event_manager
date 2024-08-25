# File class : allows you to perform a large number of operations
# on files on your filesystem

File.exist? "event_attendees.csv"

# File.read : Read file (returns file as a single string)
contents = File.read('event_attendees.csv')

# File.readlines : Read the file line by line (returns an array of lines)
lines = File.readlines ('event_attendees.csv')
