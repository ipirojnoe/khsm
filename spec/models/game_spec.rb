# (c) goodprogrammer.ru

require 'rails_helper'
require 'support/my_spec_helper' # наш собственный класс с вспомогательными методами

# Тестовый сценарий для модели Игры
# В идеале - все методы должны быть покрыты тестами,
# в этом классе содержится ключевая логика игры и значит работы сайта.
RSpec.describe Game, type: :model do
  # пользователь для создания игр
  let(:user) { FactoryGirl.create(:user) }

  # игра с прописанными игровыми вопросами
  let(:game_w_questions) { FactoryGirl.create(:game_with_questions, user: user) }
  let(:game_question) { FactoryGirl.create(:game_question, a: 3, b: 2, c: 4, d: 1) }

  # Группа тестов на работу фабрики создания новых игр
  context 'Game Factory' do
    it 'Game.create_game! new correct game' do
      # генерим 60 вопросов с 4х запасом по полю level,
      # чтобы проверить работу RANDOM при создании игры
      generate_questions(60)

      game = nil
      # создaли игру, обернули в блок, на который накладываем проверки
      expect {
        game = Game.create_game_for_user!(user)
      }.to change(Game, :count).by(1).and(# проверка: Game.count изменился на 1 (создали в базе 1 игру)
        change(GameQuestion, :count).by(15).and(# GameQuestion.count +15
          change(Question, :count).by(0) # Game.count не должен измениться
        )
      )
      # проверяем статус и поля
      expect(game.user).to eq(user)
      expect(game.status).to eq(:in_progress)
      # проверяем корректность массива игровых вопросов
      expect(game.game_questions.size).to eq(15)
      expect(game.game_questions.map(&:level)).to eq (0..14).to_a
    end
  end


  # тесты на основную игровую логику
  context 'game mechanics' do
    # правильный ответ должен продолжать игру
    it 'answer correct continues game' do
      # текущий уровень игры и статус
      level = game_w_questions.current_level
      q = game_w_questions.current_game_question
      expect(game_w_questions.status).to eq(:in_progress)

      game_w_questions.answer_current_question!(q.correct_answer_key)

      # перешли на след. уровень
      expect(game_w_questions.current_level).to eq(level + 1)
      # ранее текущий вопрос стал предыдущим
      expect(game_w_questions.previous_game_question).to eq(q)
      expect(game_w_questions.current_game_question).not_to eq(q)
      # игра продолжается
      expect(game_w_questions.status).to eq(:in_progress)
      expect(game_w_questions.finished?).to be_falsey
    end

    it 'takes money and game finished' do
      # берем игру и отвечаем на текущий вопрос
      q = game_w_questions.current_game_question
      game_w_questions.answer_current_question!(q.correct_answer_key)
    
      # взяли деньги
      game_w_questions.take_money!
    
      prize = game_w_questions.prize
      expect(prize).to be > 0
    
      # проверяем что закончилась игра и пришли деньги игроку
      expect(game_w_questions.status).to eq :money
      expect(game_w_questions.finished?).to be_truthy
      expect(user.balance).to eq prize
    end

    it 'returns correct answer key' do
      expect(game_question.correct_answer_key).to eq('d')
    end

    it 'returns current game question' do
      expect(game_w_questions.current_game_question).to eq(game_w_questions.game_questions[0])
    end

    it 'returns previous level' do
      expect(game_w_questions.previous_level).to eq(-1)
    end
  end

  context 'game answer_current_question!' do
    let(:correct_answer_key) { game_w_questions.current_game_question.correct_answer_key }

    it 'game finished' do
      game_w_questions.created_at = 40.minutes.ago
      expect(game_w_questions.answer_current_question!(correct_answer_key)).to be_falsey
      expect(game_w_questions.finished?).to be_truthy
      expect(game_w_questions.status).to eq(:timeout)
    end

    it 'correct answer' do
      expect(game_w_questions.answer_current_question!(correct_answer_key)).to be_truthy
      expect(game_w_questions.finished?).to be_falsey
      expect(game_w_questions.status).to eq(:in_progress)
    end

    it 'correct answer and finish game' do
      game_w_questions.current_level = Question::QUESTION_LEVELS.max
      expect(game_w_questions.answer_current_question!(correct_answer_key)).to be_truthy
      expect(game_w_questions.finished?).to be_truthy
      expect(game_w_questions.status).to eq(:won)
    end

    it 'wrong answer' do
      expect(game_w_questions.answer_current_question!('wrong answer')).to be_falsey
      expect(game_w_questions.finished?).to be_truthy
      expect(game_w_questions.status).to eq(:fail)
    end
  end

  context 'game status' do
    it 'fail' do
      game_w_questions.is_failed = true
      game_w_questions.finished_at = Time.now + 30.minutes
      expect(game_w_questions.status).to eq(:fail)
    end

    it ':timeoute' do
      game_w_questions.is_failed = true
      game_w_questions.finished_at = Time.now + 36.minutes
      expect(game_w_questions.status).to eq(:timeout)
    end

    it 'won' do
      game_w_questions.finished_at = Time.now + 5.minutes
      game_w_questions.current_level = Question::QUESTION_LEVELS.max + 1
      expect(game_w_questions.status).to eq(:won)
    end

    it 'money' do
      game_w_questions.finished_at = Time.now + 5.minutes
      game_w_questions.current_level = Question::QUESTION_LEVELS.max
      expect(game_w_questions.status).to eq(:money)
    end

    it 'in progress' do
      expect(game_w_questions.status).to eq(:in_progress)      
    end
  end
end
