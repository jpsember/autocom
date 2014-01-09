class Match

  # The text containing the autocompletion stub
  attr_reader :target

  # The stub, a substring at the end of the target
  attr_reader :stub

  # The suggested completion for the stub
  attr_reader :completion

  def initialize(target,stub,completion)
    @target = target
    @stub = stub
    @completion = completion
  end

  def to_s
    s = @target[0..-@stub.length-1]
    s << '[' << @completion << ']'
    s
  end

end
