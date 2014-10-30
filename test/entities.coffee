entities = require '../src/entities'
assert = require 'assert'

describe 'entities test', () ->
  
  testEncode = (decoded, encoded) ->
    it "can encode from #{decoded} to #{encoded}", (done) ->
      try
        assert.equal entities.encode(decoded), encoded
        assert.equal entities.decode(encoded), decoded
        done null
      catch e
        done e
  
  testEncode 'abc\n', 'abc\n'
  testEncode 'abc <', 'abc &lt;'

  it 'can convert numeric values', (done) ->
    try 
      assert.equal entities.decode('&#39;'), entities.decode('&apos;')
      assert.equal entities.decode('&#x27;'), entities.decode('&apos;')
      done null
    catch e
      done e
  