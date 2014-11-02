path = require 'path'
mockquery = require '../src/mockquery'
assert = require 'assert'

describe 'class test', () ->
  $ = mockquery.readFileSync path.join __dirname, '../example/class.html'
  testClassCountCase = (cls, count) ->
    it "should select #{cls} only", (done) ->
      try 
        assert.equal $(cls).length, count
        done null
      catch e
        done e
        
  testClassCountCase '.c1', 4
  
  testClassCountCase '.c2', 2
