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

COMMIT_FORMAT_STR = "  %-24s%s"

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

INPUT_FORMAT_STR   = "  %-32s min: %-6s max: %-6s %-16s values: %s"

def computational_input_report(computational_inputs, runs)
  puts
  puts "Computational inputs: #{computational_inputs.length}"
  computational_inputs.each_index do |index|
    input = computational_inputs[index]
    values_string = runs.collect { |run| sprintf("%-8s", run['computationalInputs'][index]) }.join
    puts sprintf(INPUT_FORMAT_STR, input['label'], input['min'], input['max'], input['units'], values_string)
  end
  puts
end

OUTPUT_FORMAT_STR   = "  %-32s min: %-6s max: %-6s %-16s values: %s"

def computational_output_report(computational_outputs, runs)
  puts "Computational outputs: #{computational_outputs.length}"
  computational_outputs.each_index do |index|
    output = computational_outputs[index]
    values_string = runs.collect { |run| sprintf("%-8s", run['computationalOutputs'][index]) }.join
    puts sprintf(OUTPUT_FORMAT_STR, output['label'], output['min'], output['max'], output['units'], values_string)
  end
  puts
end

REPRESENTATIONAL_FORMAT_STR   = "  %-32s                         %-16s values: %s"

def representational_input_report(representational_inputs, runs)
  puts "Representational inputs: #{representational_inputs.length}"
  representational_inputs.each_index do |index|
    input = representational_inputs[index]
    values_string = runs.collect { |run| sprintf("%-8s", run['representationalInputs'][index]) }.join
    puts sprintf(REPRESENTATIONAL_FORMAT_STR, input['label'], input['units'], values_string)
  end
  puts
end

STUDENT_FORMAT_STR   = <<-HEREDOC
  %s:
%s
HEREDOC

def student_input_report(student_inputs, runs)
  puts "Student inputs: #{student_inputs.length}"
  student_inputs.each_index do |index|
    input = student_inputs[index]
    values_string = runs.collect { |run| sprintf("    - %-32s\n", run['studentInputs'][index]) }.join
    puts sprintf(STUDENT_FORMAT_STR, input['label'], values_string)
  end
  puts
end

RE = /^\[([0-9.]+) ([0-9.]+) ([0-9.]+) ([0-9.]+) ([0-9.]+) (Yes|No) (false|true) (.*?) (false|true) ([0-9.]+) (\[[0-9.]*\]) (\[[0-9.]*\]) \[(.*?)\] (false|true) ([0-9.]+) ([0-9.]+) (false|true) ([0-9.]+) ([0-9.]+) ([0-9.]+) (false|true) ([0-9.]+)\]/

def custom_inquiry_summary_report(runs)
  puts "Custom Inquiry Summary:"
  summary = []
  runs.each do |r|
    summary << r['inquirySummary']
  end
  summary.each do |line|
    unless line =~ /"/
      line.gsub!(RE) { |m| "[#{$1} #{$2} #{$3} #{$4} #{$5} \"#{$6}\" #{$7} \"#{$8}\" #{$9} #{$10} #{$11} #{$12} [\"#{$13}\"] #{$14} #{$15} #{$16} #{$17} #{$18} #{$19} #{$20} #{$21} #{$22}]" }
    end
  end
  puts summary.join("\n")
  puts
end

#
# "modelInformation"=>
#     [{"name"=>"airbags",
#       "fileName"=>"airbags.v19b-include-modular.nlogo",
#       "version"=>"v19b-include-modular"}]
#

MODEL_FORMAT_STR = <<-HEREDOC
  name:      %s
  filename:  %s
  version:   %s
HEREDOC

def model_information_report(description)
  puts
  puts "Model Information:"
  if description
    model_info = description['modelInformation']
    model_info = model_info[0] if model_info.class == Array
    puts sprintf(MODEL_FORMAT_STR, model_info['name'], model_info['fileName'], model_info['version'])
  else
    puts "  not available"
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
  if s[/"\{\\n/]
    s = s.gsub('\\"', '"').gsub('\\n', "\n").gsub(/^\"/, '').gsub(/"$/, '')
  end
  if s.empty?
    row[:student_work] = "nodata"
  else
    @parsed_twice = false
    begin
      # debugger
      row[:student_work] = JSON.parse(s)
    rescue JSON::ParserError
      # debugger
      if @parsed_twice
        row[:student_work] = "invalid JSON"
      else
        # deal with early generation of invalid JSON in inquirySummary field:
        # "inquirySummary":[10 0.38 0.24 0.012 56.9 Yes false  false 0 [] [1] [] false 0 0 false 0 0 0 false 0]\n
        s.gsub!(/"inquirySummary\":\[(.*?)\]\n/) { |m| "\"inquirySummary\":\"\[" + $1 + "\]\"\n" }
        @parsed_twice = true
        retry
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
      model_information_report(description)
      if runs
        puts "Number of runs: #{runs.length}"
        computational_input_report(description["computationalInputs"], runs)
        computational_output_report(description["computationalOutputs"], runs)
        representational_input_report(description["representationalInputs"], runs)
        student_input_report(description["studentInputs"], runs)
        custom_inquiry_summary_report(runs)
        puts
      else
        puts "Number of runs: 0"
        puts
      end
    end
  end
end
