require 'pry'
require 'yaml'

module FileManager
  def save_game_to_file(save)
    File.open('save.txt', "w") { |f| f.write(YAML.dump(save)) }
  end

  def load_game_from_file
    YAML.load(File.read("save.txt"))
  end
end

class Save
  attr_accessor :code, :guesses
  def initialize(code, guesses)
    @code = code
    @guesses = guesses
  end
end

class Dictionary
  def initialize(words)
    @words = words
  end

  def random_word
    valid_word = false
    while valid_word == false
      word = @words.sample.downcase
      valid_word = true if word.length > 4 && word.length < 13
    end
    return word
  end
end

class HiddenWord
  attr_accessor :coded_word, :word
  def initialize(word)
    @word = word
    @coded_word = ''
    word.each_char { @coded_word += '_'}
  end

  def print_with_gaps
    print "\n"
    @coded_word.each_char { |char| print char + ' ' }
    print "\n"
  end

  def substitute_letters (positions_array, letter)
    positions_array.each { |position| @coded_word[position] = letter}
  end
end

class Hangman
  include FileManager

  attr_accessor :hidden_world, :remaining_guesses

  def initialize(hidden_world)
    @hidden_world = hidden_world
    @remaining_guesses = 6
  end

  def mode_select
    puts "Let's play Hangman!"
    puts 'Do you want to play a new game or load a saved one? Type new or load and press enter!'
    valid_mode_fetch == 'new' ? start_game : loader
  end

  def valid_mode_fetch
    valid_mode = false
    while valid_mode == false
      mode = gets.chomp.downcase
      if mode == 'new' || mode == "load"
        valid_mode = true
      else
        puts 'Invalid mode! Type new or load and press enter!'
      end
    end
    return mode
  end

  def start_game
    puts 'At any time, type "save" and press enter to save and exit the game!'
    @hidden_world.print_with_gaps
    until @remaining_guesses.zero?
      puts "\n\nYou have #{@remaining_guesses} guesses left!\n"
      result = play_round(get_valid_letter)
      result.empty? ? @remaining_guesses -= 1 : win?
    end
    game_over_lose
  end

  def loader
    game = load_game_from_file
    @hidden_world = game.code
    @remaining_guesses = game.guesses
    start_game
  end

  def win?
    game_over_win if @hidden_world.word == @hidden_world.coded_word
  end

  def game_over_win
    puts 'You won! Congratulations!'
    exit(true)
  end

  def game_over_lose
    puts "You lost! The word was #{@hidden_world.word}! Better luck next time!"
    exit(true)
  end

  def play_round(guess)
    right_guesses = search_letter(@hidden_world.word, guess)
    @hidden_world.substitute_letters(right_guesses, guess)
    @hidden_world.print_with_gaps
    return right_guesses
  end

  def get_valid_letter
    valid_letter = false
    while valid_letter == false
      puts "\nType the letter you want to guess and press enter!"
      letter = gets.chomp.downcase
      if letter == 'save'
        save_game
      elsif (letter =~ /[^a-z]/).nil? && letter.length == 1
        valid_letter = true
        return letter
      else
        puts'Invalid letter!'
      end
    end
  end

  def search_letter(word, letter)
    starting_point = 0
    letter_occurrences = []
    stop = false
    until stop == true
      result = word.index(letter, starting_point)
      if result.nil?
        break
      else
        letter_occurrences.push(result)
        starting_point = result += 1
      end
    end
    return letter_occurrences
  end

  def save_game
    save_data = Save.new(@hidden_world, @remaining_guesses)
    save_game_to_file(save_data)
    puts 'Game saved! Bye!'
    exit(true)
  end
end

file = File.open('dictionary.txt')
words = file.readlines.map(&:chomp)
file.close
dictionary = Dictionary.new(words)

palavra_secreta = HiddenWord.new(dictionary.random_word)
novo_jogo = Hangman.new(palavra_secreta)
novo_jogo.mode_select