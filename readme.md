### NetLogo models instrumented for inquiry data logging for VISUAL project.

Try these out here: http://concord-consortium.github.io/netlogo-visual/index.html


### Local development

Ruby 1.9.3 or 2.0 and the Ruby Gem bundler are prerequisites for running a local server.

1. Clone repo and cd into working dir
2. `bundle install --binstubs`
3. `bin/rackup config.ru`
4. open http://localhost:9292/index.html

### Processing NetLogo inquiry-logging data from a WISE project run CSV research export of student work

1. Login to http://wise.berkeley.edu.
2. Open "Researcher Tools (Export Student Data)" for the project run with NetLogo steps instrumented for inquiry-logging.
3. Select the **CSV** option for **Export All Student Work** and save it in the `exports/` folder.
4. Run the Ruby program `wise-netlogo-export.rb` with the path to the download

    $ ruby wise-netlogo-export.rb 'exports/Designing a Safer Airbag (P)-4239-all-student-work.csv'

