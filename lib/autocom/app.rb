#!/usr/bin/env ruby

require 'autocom'
require 'autocom/prediction_tree_builder'

class AutoComApp

  def run(argv=ARGV)

    p = Trollop::Parser.new do
            banner <<-EOS
Uses a prediction tree algorithm to suggest the most likely n autocompletions for a word.
EOS
      opt :corpus,"corpus xxx[.txt|.predtree]",:type => :string
      opt :window,"window size (for prediction tree algorithm)",:type => :integer,:default => 5
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

    ac = get_prediction_tree(corpus_path)

    puts "Prediction Tree:\n-------------------------------------\n#{ac}" if options[:verbose]

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


  def get_word_map_from_file(corpus_path)
  end

  def build_tree(path)
    corpus_text = FileUtils.read_text_file(FileUtils.change_extension(path,'.txt'))
    corpus_text = Corpus.process_frequency_tags(corpus_text)
    corpus = Corpus.new(corpus_text)
    tree = PredictionTreeBuilder.build_from_word_frequency_map(corpus.word_frequency_map)
    tree_path = FileUtils.change_extension(path,'.predtree')
    FileUtils.write_text_file(tree_path,tree.to_json)
    tree
  end

  def read_tree(path)
    PredictionTree.read_from_json(FileUtils.read_text_file(FileUtils.change_extension(path,'.predtree')))
  end

  def get_prediction_tree(corpus_path)
    ext = File.extname(corpus_path)
    if ext == ''
      if File.file?(corpus_path+'.predtree')
        ext = '.predtree'
      elsif File.file?(corpus_path+'.txt')
        ext = '.txt'
      end
    end

    if ext == '.predtree'
      return read_tree(corpus_path)
    elsif ext == '.txt'
      return build_tree(corpus_path)
    end
    die "Not a recognized file: #{corpus_path}"
  end

end

