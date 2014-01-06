#!/usr/bin/env ruby

require 'js_base'

req 'match corpus ngrams autocomplete prediction_tree', 'autocom'

class AutoComApp


  def run(argv=ARGV)

    p = Trollop::Parser.new do
            banner <<-EOS
Performs autocompletion using most likely unigrams and bigrams taken from a corpus.

EOS
      opt :corpus,"corpus",:type => :string
      opt :window,"window size",:type => :integer
      opt :unigram,"unigram log probability",:type => :float
      opt :bigram,"bigram log probability",:type => :float
      opt :verbose,"verbose"
    end

    options = Trollop::with_standard_exception_handling p do
      p.parse argv
    end

    corpus_path = options[:corpus]
    die "Must specify corpus text file" if !corpus_path

    msg =<<-EOS

Performs autocompletion based on a corpus.

Type a sentence; you can also use these special keys:

  tab    : uses first suggestion
  delete : delete last character
  q      : quit

EOS
    puts msg

    corpus_text = FileUtils.read_text_file(corpus_path)
    corpus_text = apply_frequency_filter(corpus_text)

    if options[:window]
      corpus = Corpus.new(corpus_text)
      ac = PredictionTree.new(corpus,options[:window])
      puts "Prediction Tree:\n-------------------------------------\n#{ac}" if options[:verbose]
    else
      ac = AutoComplete.new(corpus_text,8,options[:unigram],options[:bigram])
    end

    quit_flag = false

    text = ''

    while !quit_flag
      puts
      matches = ac.match(text)
      matches.each do |match|
        puts match
      end
      puts " ==> #{text}|"

      cmd = RubyBase.get_user_char('q')

      case cmd
      when 'q'
        quit_flag = true
      when 127.chr
        if text.size > 0
          text.slice!(-1..-1)
        end
      when 13.chr
        puts
        puts
        text = ''
      when 9.chr
        if !matches.empty?
          match = matches[0]
          text[-match.prefix.length..-1] = match.text + ' '
        end
      else
        text << cmd
      end
    end
  end

  def apply_frequency_filter(txt)
    ends_with_freq = Regexp.new(".*\\.(\\d+)$")
    txt2 = ''
    txt.lines.each do |line|
      line.chomp!
      match = ends_with_freq.match(line)
      if match
        rep = match[1].to_i
        skip_digits = match[1].length + 1
        line = line[0...-skip_digits]
        line += ' '
        line *= rep
      end
      txt2 << line << "\n"
    end
    txt2
  end

end

