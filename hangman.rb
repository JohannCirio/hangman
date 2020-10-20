require 'pry'
require 'yaml'

module FileManager
  def create_save_directory
    Dir.mkdir('saves') if !Dir.exist?('saves')
  end

  def save_game_to_file(save, save_name)
    File.open("saves/#{save_name}.txt", "w") { |f| f.write(YAML.dump(save)) }
  end

  def load_game_from_file(file_name)
    YAML.load(File.read(file_name))
  end

  def list_files(directory)
    formated_files = []
    all_files = Dir.glob("#{directory}/*")
    all_files.each { |file| formated_files.push(file.delete_prefix('saves/').delete_suffix('.txt')) }
    return formated_files
  end
end

module TerminalControl
  def clean_line
    print "\r"
  end

  def clean_lines(number_of_lines)
    clean_line
    number_of_lines.times { print "\033[A\033[K" }
  end

  def cursor_up (number_of_lines)
    print "\033[#{number_of_lines}A"
  end

  def cursor_forward(number_of_rows)
    print "\033[#{number_of_rows}C"
  end
end

class Save
  attr_accessor :code, :guesses, :wrong_guesses, :hanged_man
  def initialize(code, guesses, wrong_guesses, hanged_man)
    @code = code
    @guesses = guesses
    @wrong_guesses = wrong_guesses
    @hanged_man = hanged_man
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
    @coded_word.each_char { |char| print char + ' ' }
    print "\n"
  end

  def substitute_letters (positions_array, letter)
    positions_array.each { |position| @coded_word[position] = letter}
  end
end

class HangedMan
  attr_accessor :head, :left_leg, :left_arm, :right_arm, :right_leg, :torso
  def initialize
    @head = ' '
    @left_arm = ' '
    @right_arm = ' '
    @torso = ' '
    @left_leg = ' '
    @right_leg = ' '
  end
end

class Hangman
  include FileManager
  include TerminalControl
  attr_accessor :hidden_world, :remaining_guesses

  def initialize(hidden_world)
    @hidden_world = hidden_world
    @remaining_guesses = 6
    @wrong_guesses = []
    @hanged_man = HangedMan.new
  end

  def mode_select
    create_save_directory
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
        clean_lines(1)
      end
    end
    return mode
  end

  def start_game
    until @remaining_guesses.zero?
      update_hanged_man
      game_ui
      result = play_round(get_valid_letter)
      result.empty? ? @remaining_guesses -= 1 : win?
    end
    game_over_lose
  end

  def game_ui
    system('clear')
    puts 'At any time, type "save" and press enter to save and exit the game!'
    print_gallows
    cursor_up(5)
    cursor_forward(18)
    puts @hidden_world.print_with_gaps
    cursor_forward(18)
    print_wrong_guesses
    puts "\n\nYou have #{@remaining_guesses} guesses left!\n"
  end

  def print_gallows
    puts "  ___________"
    puts "  |         |"
    puts "  |         #{@hanged_man.head}"
    puts "  |        #{@hanged_man.left_arm}#{@hanged_man.torso}#{@hanged_man.right_arm}"
    puts "  |        #{@hanged_man.left_leg} #{@hanged_man.right_leg}"
    puts "  |           "
    puts "  |"
  end

  def update_hanged_man
    case @remaining_guesses
    when 5
      @hanged_man.head = '0'
    when 4
      @hanged_man.torso = "|"
    when 3
      @hanged_man.left_arm = '/'
    when 2
      @hanged_man.right_arm = "\\"
    when 1
      @hanged_man.left_leg = "/"
    when 0 
      @hanged_man.right_leg = "\\"
    end
  end

  def print_wrong_guesses
    print "Wrong guesses:  "
    @wrong_guesses.each {|guess| print "[#{guess}]"} unless @wrong_guesses.empty?
    print "\n\n"
  end

  def loader
    system('clear')
    save_files_list = list_files('saves')
    print_files_list(save_files_list)
    save_file_name = select_save_file(save_files_list)
    save_file_name = 'saves/' + save_file_name + '.txt'
    load_game(load_game_from_file(save_file_name))
    start_game
  end

  def load_game(save)
    @hidden_world = save.code
    @remaining_guesses = save.guesses
    @wrong_guesses = save.wrong_guesses
    @hanged_man = save.hanged_man
  end

  def print_files_list (file_names)
    puts "Available save files:\n\n"
    file_names.each { |file| puts file }
  end

  def select_save_file (available_files)
    puts "\nType the name of the file you want to load and press enter!"
    valid_file = false
    until valid_file == true
      load_file = gets.chomp
      available_files.any? { |file| file == load_file } ? valid_file = true : clean_lines(1)
    end
    return load_file
  end

  def win?
    game_over_win if @hidden_world.word == @hidden_world.coded_word
  end

  def game_over_win
    update_hanged_man
    game_ui
    puts 'You won! Congratulations!'
    exit(true)
  end

  def game_over_lose
    update_hanged_man
    game_ui
    puts "You lost! The word was #{@hidden_world.word}! Better luck next time!"
    exit(true)
  end

  def play_round(guess)
    right_guesses = search_letter(@hidden_world.word, guess)
    if right_guesses.empty?
      save_wrong_guess(guess) if right_guesses.empty?
    end
    @hidden_world.substitute_letters(right_guesses, guess)
    return right_guesses
  end

  def save_wrong_guess(guess)
    puts "ENTREI"
    @wrong_guesses.push(guess) if @wrong_guesses.none? { |letter| letter == guess }
  end

  def get_valid_letter
    valid_letter = false
    while valid_letter == false
      puts "Type the letter you want to guess and press enter!"
      letter = gets.chomp.downcase
      if letter == 'save'
        save_game
      elsif @wrong_guesses.any? { |wrong_guess| wrong_guess == letter}
        clean_lines(2)
      elsif (letter =~ /[^a-z]/).nil? && letter.length == 1
        valid_letter = true
        return letter
      else
        clean_lines(2)
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
    system("clear")
    save_data = Save.new(@hidden_world, @remaining_guesses, @wrong_guesses, @hanged_man)
    save_name = get_valid_save_name
    save_game_to_file(save_data, save_name)
    puts 'Game saved! Bye!'
    exit(true)
  end

  def get_valid_save_name
    puts 'Type a name for your save file and press enter! (please use only letters, numbers and underscore)'
    valid_name = false
    until valid_name == true
      name = gets.chomp.downcase
      if (name =~ /\W/).nil? && name.length < 25
        valid_name = true
      else
        clean_lines(1)
      end
    end
    return name
  end
end

file = File.open('dictionary.txt')
words = file.readlines.map(&:chomp)
file.close
dictionary = Dictionary.new(words)

palavra_secreta = HiddenWord.new(dictionary.random_word)
novo_jogo = Hangman.new(palavra_secreta)
system("clear")
novo_jogo.mode_select