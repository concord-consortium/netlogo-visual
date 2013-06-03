#
# file: wise-netlogo-export.rb
#
# Ruby 1.9 stdlib documentation:
#
#   csv:  http://rubydoc.info/stdlib/csv/1.9.2/frames
#   json: http://rubydoc.info/stdlib/json/1.9.2/frames
#

require 'csv'
require 'json'
require 'pp'
require 'optparse'

opts = OptionParser.new
arguments = opts.parse(ARGV)

if arguments.empty?
  @filename = "exports/Designing a Safer Airbag (P)-4239-all-student-work.csv"
else
  @filename = arguments[0]
end

# -----------------------------------

def process_csv(filename)
  @import_lines = File.readlines(filename)
  @import_project = @import_lines[0..1]
  lines = [@import_lines[3].gsub(/^"#"/, '"number"')]
  rownum = 0
  rows = @import_lines.length
  while rownum < rows
    row = @import_lines[rownum]
    if row[/^"Workgroup Id"/]
      rownum += 4
    else
      lines << row
      rownum += 1
    end
  end
  lines.join
end

def computational_output_report(computational_outputs, runs)
  puts "Computational outputs: #{computational_outputs.length}"
  computational_outputs.each_index do |index|
    output = computational_outputs[index]
    print "#{output['label']}, min: #{output['min']}, max: #{output['max']} #{output['units']}: values("
    print runs.collect { |run| run['computationalOutputs'][index] }.join(", ")
    puts ")"
  end
  puts
end

def computational_input_report(computational_inputs, runs)
  puts
  puts "Computational inputs: #{computational_inputs.length}"
  computational_inputs.each_index do |index|
    input = computational_inputs[index]
    print "#{input['label']}, min: #{input['min']}, max: #{input['max']} #{input['units']}: values("
    print runs.collect { |run| run['computationalInputs'][index] }.join(", ")
    puts ")"
  end
  puts
end

#####################################
#
# Main program
#
#####################################

@import = process_csv(@filename)
@import.gsub!(/^"#"/, '"number"')

@table = CSV.parse(@import, headers: true, header_converters: :symbol, converters: :all)

# Original Headers:
#
#  "#","Workgroup Id","WISE Id 1","WISE Id 2","WISE Id 3","Step Work Id","Step Title","Step Type","Step Prompt",
#  "Node Id","Post Time (Server Clock)","Start Time (Student Clock)","End Time (Student Clock)",
#  "Time Spent (Seconds)","Teacher Score Timestamp","Teacher Score","Teacher Comment Timestamp","Teacher Comment",
#  "Classmate Id","Receiving Text","Student Work"
#
# Headers (converted to Ruby symbols):
#
#   :number, :workgroup_id, :wise_id_1, :wise_id_2, :wise_id_3, :step_work_id, :step_title, :step_type, :step_prompt,
#   :node_id, :post_time_server_clock, :start_time_student_clock, :end_time_student_clock,
#   :time_spent_seconds, :teacher_score_timestamp, :teacher_score, :teacher_comment_timestamp, :teacher_comment,
#   :classmate_id, :receiving_text, :student_work]

@headers = @table.headers

@steptypes = @table[:step_type].uniq

@workgroups = @table[:workgroup_id].uniq
@workgroup_tables = {}
@workgroups.each do |workgroup|
  @workgroup_tables[workgroup] = CSV::Table.new(@table.find_all { |row| row[:workgroup_id] == workgroup }.sort { |a,b| a[:start_time_student_clock] <=> b[:end_time_student_clock] })
end

@netlogo_step_data = @table.find_all { |row| row[:step_type] == "Netlogo" }

RESPONSE_PREFIX = "Response #1: "

@netlogo_step_data.each do |row|
  s = row[:student_work].gsub(RESPONSE_PREFIX, '')
  if s.empty?
    row[:student_work] = "nodata"
  else
    row[:student_work] = JSON.parse(s)
  end
end

puts <<-HEREDOC

Parsing:    #{@filename}
Rows:       #{@table.count}
Workgroups: #{@workgroups.length}

Headers:    #{@headers}

Step Types: #{@steptypes}

NetLogo step sessions:    #{@netlogo_step_data.length}

HEREDOC

@workgroup_tables.each do |workgroup, table|
  nl_table = table.find_all { |row| row[:step_type] == "Netlogo" }
  puts <<-HEREDOC

================================================================
Workgroup: #{workgroup}
NetLogo steps: #{nl_table.length}
  HEREDOC

  if nl_table.count > 0
    nl_table.each do |row|
      student_work = row[:student_work]
      s = PP.pp(student_work, dump = "")
      puts "--------------------------------------------------------"
      puts "Step name:      #{row[:step_title]}"
      puts "Total time:     #{row[:time_spent_seconds]} s"
      runs = student_work['runs']
      description = student_work["description"]
      if runs
        puts "Number of runs: #{runs.length}"
        computational_input_report(description["computationalInputs"], runs)
        computational_output_report(description["computationalOutputs"], runs)
        puts
        puts runs.collect {|r| r['inquirySummary'] }.join("\n")
        puts
        puts s
        puts
      else
        puts "Number of runs: 0"
      end
    end
  end
end

puts <<-HEREDOC

Parsing:    #{@filename}
Rows:       #{@table.count}
Workgroups: #{@workgroups.length}

Headers:    #{@headers}

Step Types: #{@steptypes}

NetLogo step sessions:    #{@netlogo_step_data.length}

HEREDOC
