require 'rails_helper'

RSpec.describe 'users/show', type: :view do
  let(:game) { FactoryGirl.create(:game, created_at: Time.parse('02.02.2021 13:37'), current_level: 6, prize: 1000) }

  context 'Anon user' do
    before(:each) do
      assign(:user, FactoryGirl.build_stubbed(:user, name: 'Вадик', balance: 5000))

      render
    end

    it 'should display user name' do
      expect(rendered).to match 'Вадик'
    end

    it 'should not display change profile link' do
      expect(rendered).not_to match 'Сменить имя и пароль'
    end
  end

  context 'Auth user' do
    before(:each) do
      user = FactoryGirl.create(:user, name: 'Вадик', balance: 5000)

      sign_in user

      assign(:user, user)
      assign(:game, game)

      render
    end

    it 'should display user name' do
      expect(rendered).to match 'Вадик'
    end

    it 'should display change profile link' do
      expect(rendered).to match 'Сменить имя и пароль'
    end

    it 'should display games' do
      render partial: 'users/game', object: game

      expect(rendered).to match '1 000 ₽'
      expect(rendered).to match 'в процессе'
      expect(rendered).to match '6'
      expect(rendered).to match '02 февр., 13:37'
    end
  end
end
