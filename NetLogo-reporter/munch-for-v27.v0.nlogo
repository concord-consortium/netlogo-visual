; Analysis software for Airbags v26
; Bob Tinker
; June 10, 2013
; Copyright 2013, the Concord Consortium. 


to munch      ; computes and reports patterns from run-data
  clear-output
  let run-data read-from-string run-data-word ; since run-data-word has the form "[...]" run-data becomes a list
  let version-number first run-data
  if int version-number != 27 [user-message "These data are not from version 27.x. There may be problems"]
  ; run-data should consist of a list of n + 1 items in pure numerical format. The first is just the version number
  ; all other items are data from n runs. 
  ; The original way I saved and analyzed data included quoted strings and even a list of strings. fixup restores this format
  let rd fixup bf run-data   ; rd is the working version of run-data
  ; run-data has a version number as its first element. Strip it out -- so it could be checked

  ; rd is now a list of lists each containing the following data of a run (the run number is the position of the data in the list) (item + 1)
  
  ;   0. car-speed 
  ;   1. distance-to-steering-wheel 
  ;   2. airbag-size 
  ;   3. time-to-fill-bag 
  ;   4. a-max-g (maximum acceleration in g units)
  ;   5. dummy-status (yes, no, maybe)
  ;   6. dummy-crashed? logical
  ;   7. the question selected by the student 
  ;   8. slow-mo? Logical. True if the run ended with slo-mo? true
  ;   9. duration of the anaysis, in seconds  ; timer is set to zero at the end of a run and read just before beginning the next 
  ;  10. prior-runs-viewed ( a list of run numbers viewed)
  ;  11. graph-type-used (a list consisting of 1s and 2s, 1 for position, 2 for velocity)
  ;  12. run-groups-used ( a list of the texts selected using the pick-graph function)
  ;  13. used-cursor? (true false) true if the mouse ever entered the time-series graph
  ;  14. cursor-times The number of times the mouse entered the time series graph area when only one graph was showing
  ;  15. cursor-time The total time the mouse was in the time-series graph in seconds when only one graph was showing
  ;  16. used-pointer? true if the mouse ever entered the parameter graph
  ;  17. pointer-times The number of times the mouse entered the parameter graph area
  ;  18. pointer-time The total time the mouse was in the parameter graph area
  ;  19. hover-times  The number of times that the user hovered over a dot in the parameter graph area
  ;  20. question-needed? True if the user tried to run or change sliders but had not entered a question
  ;  21. activity-counter. An overall measure of student interaction--the number of actions a student takes


  output-print word "Using version     " version-number
  output-print word "Number of runs: " length rd
  compute-boundaries rd; first, computer and report the range of values used for each variable 
  show-results-by-run rd ; now show results for each run
;  further-analysis rd
end 
    
to further-analysis [rundata] ; not yet implemented....

  ; now look at successive pairs of values
  let cov [0 0 0 0]          ; this list will count the number of times only one variable was changed
  let repeats 0
  while [length rundata > 1] [   ; at least one pair of runs is needed
    let current-run sublist (item 1 rundata) 0 4                ; current-run is a list of the first four values for the curent run
    let old-run sublist (first rundata ) 0 4                    ; ditto for the run before--the old run
    let match same? current-run old-run                    ; generates a list of 4 values: 0 if the two corresponding elements are the same, 1 otherwise
    let changes reduce + match                             ; changes is the number of variables changed
    if changes = 0 [set repeats repeats + 1]               ; if nothing was changed, then increment the number of repeats
    if changes = 1 [                                       ; if only one variable was changed....
      if non-zero current-run = non-zero old-run []
      
    ]
      
;      set cov mult-lists match (sum-lists match cov) ]     ;    compute a new CoV list. addition adds one to the right variable, multiplication zeros out those not changed
    if changes > 1 [set cov [0 0 0 0] ]                     ; if two variables were changed, reset CoV. 
    set rundata bf rundata ]                                         ; chop off the first run, get ready to process the next pair
end
  
to-report same? [list1 list2]  ; goes through the two lists looking for numerical differences in the elements
  ; reports a list of elements. For each item 1 means list elements are different or 0 means that the two are identical
  let list3 [ ]  let i 0 
  while [i < length list1][
    ifelse (item i list1) = (item i list2)
      [set list3 lput 1 list3]
      [set list3 lput 0 list3]
    set i i + 1 ]
  report list3
end

to-report non-zero [list1]
  let i 0
  while [i < length list1 ][
    if (item i list1) != 0 [report i]
    set i i + 1 ]
  report -1
end

to-report pad [txt n]; Pads out the text txt to be n spaces long, putting spaces after the txt. Useful in lining up text in the output box
  let k length txt ; find out how long txt is TXT MUST BE A TEXT STRING
  if k >= n [report txt] ; if txt is too long, just return txt
  repeat n - k [set txt word txt " "]  ; add k-n spaces
  report txt
end

to compute-boundaries [rundata]; first, get the range of values used for each variable 
  let car-min 2 let car-max 30    
  let dist-min .1 let dist-max .5 
  let size-min .2 let size-max .5 
  let time-min .01 let time-max .05   ; note, this is the time for the airbag to fill

  
  let n-boundaries 0
  let car-values []  let dist-values [] 
  let size-values [] let time-values []
  let duration 0
  while [not empty? rundata ] [                            ; repeat for each run
    let temp first rundata                                ; get the data for a run--place in temp
    set car-values lput first temp car-values         ; collect all the car-speed values into a list
    set dist-values lput item 1 temp dist-values      ;    ditto for distance values
    set size-values lput item 2 temp size-values      ;    and airbag size values
    set time-values lput item 3 temp time-values      ;    and time-to-fill values
    set duration duration + item 9 temp               ; sum up the durations of each run
    set rundata bf rundata ]                                    ; chop off the first list and repeat
  output-print (word "Total time: " round duration " sec")
  
  let sorted-car-values  sort remove-duplicates car-values    ; sort the values and remove duplicates
  let sorted-dist-values sort remove-duplicates dist-values
  let sorted-size-values sort remove-duplicates size-values
  let sorted-time-values sort remove-duplicates time-values
  let smallest-car  first sorted-car-values           ; find the smallest value used
  let largest-car    last  sorted-car-values           ;      and the largest
  let smallest-dist first sorted-dist-values
  let largest-dist  last  sorted-dist-values
  let smallest-size first sorted-size-values
  let largest-size  last  sorted-size-values
  let smallest-time first sorted-time-values
  let largest-time  last  sorted-time-values
  if smallest-car  <= car-min  [set n-boundaries n-boundaries + 1]   ; see whether the smallest and larest are boundary values
  if largest-car   >= car-max  [set n-boundaries n-boundaries + 1]
  if smallest-dist <= dist-min [set n-boundaries n-boundaries + 1]
  if largest-dist  >= dist-max [set n-boundaries n-boundaries + 1]
  if smallest-size <= size-min [set n-boundaries n-boundaries + 1]
  if largest-size  >= size-max [set n-boundaries n-boundaries + 1]
  if smallest-time <= time-min [set n-boundaries n-boundaries + 1]
  if largest-time  >= time-max [set n-boundaries n-boundaries + 1]
  let car-range  round (largest-car  - smallest-car) 
  let dist-range precision (largest-dist - smallest-dist) 2
  let size-range precision (largest-size - smallest-size) 2
  let time-range precision (largest-time - smallest-time) 3
  let n-cars length sorted-car-values        ; the number of unique values of car speed
  let n-dist length sorted-dist-values       ;     ditto for distance-to-steering-wheel 
  let n-size length sorted-size-values       ;     and for airbag size
  let n-time length sorted-time-values       ;     and time-to-fill values
  
  output-print word "Total number of boundaries: " n-boundaries
  output-print "For 'Car speed':"
  output-print word "   Values examined: " sorted-car-values
  output-print word "   Range: " car-range
  output-print word "   Number of unique values: " n-cars
  output-print "For 'Distance-to-steering-wheel':"
  output-print word "   Values examined: " sorted-dist-values
  output-print word "   Range: " dist-range
  output-print word "   Number of unique values: " n-dist
  output-print "For 'Airbag size':"
  output-print word "   Values examined: " sorted-size-values
  output-print word "   Range: " size-range
  output-print word "   Number of unique values: " n-size
  output-print "For 'Time-to-fill-bag':"
  output-print word "   Values examined: " sorted-time-values
  output-print word "   Range: " time-range
  output-print word "   Number of unique values: " n-time  
  output-print ""
  
end

to show-results-by-run [rundata]
  let i 0
  while [length rundata > 0 ][
    let current-run first rundata
    output-print word "For run: " (i + 1)
    output-print word  "     The question: "           (item 7  current-run)   
    output-print (word "  Slider values:")
    output-print (word "     Car speed: "              (item 0  current-run) " m/s") 
    output-print (word "     Dist to steering wheel: " (item 1  current-run) " m")
    output-print (word "     Airbag size: "            (item 2  current-run) " m")   
    output-print (word "     Time to fill bag: "       (item 3  current-run) " s")
    output-print (word "  Results of run: " )
    output-print (word "     Maximum acceleration: "   (item 4  current-run) " g")
    output-print word  "     Dummy survived? "         (item 5  current-run)
    output-print (word "  Summary of user interaction: " )    
    output-print (word "     Time spent: "             (item 9  current-run) " s")    
    output-print word  "     Overall activity level: " (item 21 current-run)  
    output-print (word "  User interaction details:")
    output-print word  "     Graphs types used: "      (item 11 current-run)
    output-print word  "     Prior graphs viewed: "    (item 10 current-run)
    output-print word  "     Slo-mo used?: "           (item 8  current-run) 
    output-print word  "     Run groups used: "        (item 12 current-run)
    output-print word  "     Used cursor?: "           (item 13 current-run)
    output-print word  "     Times cursor used: "      (item 14 current-run)
    output-print (word "     Cursor use time: "        (item 15 current-run) " s")
    output-print word  "     Used pointer?: "          (item 16 current-run)
    output-print word  "     Times pointer used: "     (item 17 current-run)
    output-print (word "     Pointer use time: "       (item 18 current-run) " s")
    output-print word  "     Times hovered: "          (item 19 current-run)       
    output-print word  "     Question needed?: "       (item 20 current-run)   

    output-print ""        
    set rundata bf rundata 
    set i i + 1 ]
  output-print ""
end

to-report fixup [run-numbers]  ; run-numbers is run data converted into pure numbers. 
  ; run-numbers is a digital version of run-data. It is a list of data from runs. Each run has 21 items
  ; this function restores the data in the runs. All this encoding and decoding is needed so that the stored run data has no quote characters.
  let runs-restored []      ; this will be a list of items, one for each rund
  while [length run-numbers > 0][ ; repeat the following for each run
    let run-restored []       ; note the singular. This will contain a list of 21 items for one run
    let one-run first run-numbers   ; one-run is pure numerical--- a list of numbers and lists of numbers
    set run-numbers bf run-numbers  ; split off the frist run (one-run) from run-numbers 
    let i 0 
    repeat length one-run [         ; now process each of the 21 elements in one-run
      let element first one-run     ; split off the first element
      set one-run bf one-run
      ; now, check for any elements that require special decoding
      if i = 5 [set element dummy-status-str element]    ; converts the number 'element' into a string that contains Yes, No, or Maybe
      if i = 6 [set element logic-str element]           ; converts element into true or false
      if i = 7 [set element the-question-str element] ; converts element into one of the questions that the user picked
      if i = 8 [set element logic-str element]           ; converts element into true or false
      if i = 12 [                                        ; this could be an empty list or a list of any number of numbers corresponding to graphs picked by user
        if not empty? element [                          ; process each item in element, converting it using pick-graph-str
          let temp []                                    ; temp will be the list of strings
          while [length element > 0 ][
            set temp lput (pick-graph-str first element) temp
            set element bf element ]
          set element temp]]
      if i = 13 or i = 16 or i = 20 [set element logic-str element]           ; converts element into true or false
      set run-restored lput element run-restored 
      set i i + 1 ]
    set runs-restored lput run-restored runs-restored ]
  report runs-restored
end

to-report dummy-status-str [n]  ; converts dummy status to a string
  if n = 0 [report "Yes"]
  if n = 1 [report "No"]
  if n = 2 [report "Maybe"]
end

to-report the-question-str [n]   ; converts the selected question number to a string
  if n = 1 [report "Test a minimum of maximum value" ]
  if n = 2 [report "Make a small change from the the last run" ]
  if n = 3 [report "Fill a gap in my results" ]
  if n = 4 [report "Do a controlled comparison" ]
  if n = 5 [report "Explore/other"]
  report ""
end 

to-report pick-graph-str [n]
  if n = 1 [report "Last 1"]
  if n = 2 [report "Last 3"]
  if n = 3 [report "Last 10"]
  if n = 4 [report "All"]
  if n = 5 [report "Blue Only (survived)"]
  if n = 6 [report "Orange Only (maybe)"]
  if n = 7 [report "Magenta Only (died)"]
  report "" 
end

to-report logic-str [n]   ; converts 0/1 to true / false
  ifelse n = 0 [report false][report true]
end

  
  
  
  
@#$#@#$#@
GRAPHICS-WINDOW
8
10
253
214
16
16
5.242424242424242
1
10
1
1
1
0
1
1
1
-16
16
-16
16
0
0
1
ticks
30.0

OUTPUT
296
10
721
615
10

INPUTBOX
5
10
293
229
Run-data-word
[[\"11:51:03.591 AM 10-Jun-2013\" \"airbags25.v1P.nlogo\"] [16 0.38 0.26 0.012 89.8 \"Yes\" false \"Make a small change from the last run\" false 18 [1] [1] [\"Last 1\"] true 2 3 true 1 3 2 false 8] [22 0.38 0.26 0.012 486.7 \"No\" true \"Make a small change from the last run\" false 19 [2] [1] [\"Last 1\"] false 0 0 false 0 0 0 false 3] [18 0.38 0.26 0.012 91.9 \"Yes\" false \"Make a small change from the last run\" false 22 [3] [1] [\"Last 1\"] true 2 0 true 1 3 0 false 6] [30 0.38 0.26 0.012 1279.7 \"No\" true \"Test a minimum or maximum value\" false 16 [4] [1] [\"Last 1\"] false 0 0 false 0 0 0 false 3] [20 0.4 0.26 0.012 150.2 \"No\" true \"Do a controlled comparison\" false 17 [5] [1] [\"Last 1\"] false 0 0 false 0 0 0 false 3] [16 0.4 0.26 0.012 92.6 \"Yes\" false \"Explore/other\" false 0 [6] [1] [\"Last 1\"] false 0 0 false 0 0 0 false 1]]
1
1
String

BUTTON
169
236
281
269
Munch
Munch
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
13
241
163
297
Paste the output data list into the Run-data window and press \"Munch\" to process it. 
11
0.0
1

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.0.3
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 1.0 0.0
0.0 1 1.0 0.0
0.2 0 1.0 0.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
