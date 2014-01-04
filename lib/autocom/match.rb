class Match

  attr_reader :prefix
  attr_reader :text
  attr_reader :target
  attr_accessor :info

  def initialize(target,prefix,text)
    @target = target
    @prefix = prefix
    @text = text
  end

  def to_s
    s = @target[0..-@prefix.length-1]
    s << '[' << @text << ']'
    if false && @info
      s << ' '*(20-(@text.length - @prefix.length))
      s << " (#{@info})"
    end
    s
  end

  def edit
    posn = @target.length - @prefix.length
    [posn,@text]
  end


  private


  def self.equivalent(m1,m2)
    p1,t1 = m1.edit
    p2,t2 = m2.edit
    if p1+t1.length == p2+t2.length
      if t1.length >= t2.length
        return t1.end_with?(t2)
      else
        return t2.end_with?(t1)
      end
    end
    false
  end

end
