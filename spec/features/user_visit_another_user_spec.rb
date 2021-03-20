require 'rails_helper'

RSpec.feature 'USER visit another user', type: :feature do
  let(:user) { FactoryGirl.create(:user, name: 'Аркадий') }
  let(:another_user) { FactoryGirl.create :user }

  let!(:games) do
    [
      FactoryGirl.create(:game, id: 13, user: another_user, created_at: Time.parse('02.02.2021 13:37'), finished_at: Time.parse('02.02.2021 13:47'),  current_level: 13, prize: 100_000),
      FactoryGirl.create(:game, id: 37, user: another_user, created_at: Time.parse('02.02.2021 13:37'), finished_at: Time.parse('02.02.2021 18:47'), current_level: 3, prize: 0 ),
      FactoryGirl.create(:game, id: 21, user: another_user, created_at: Time.now, current_level: 7, prize: 1000)
    ]
  end

  before(:each) do
    login_as user
  end

  # Сценарий успешного создания игры
  scenario 'successfully' do
    visit "/users/#{another_user.id}"

    expect(page).to have_current_path "/users/#{another_user.id}"
    expect(page).to have_link 'Аркадий - 0 ₽', href: user_path(user)
    
    expect(page).not_to have_content 'Сменить имя и пароль'
    expect(page).to have_content another_user.name

    expect(page).to have_content '13'
    expect(page).to have_content '02 февр., 13:37'
    expect(page).to have_content 'деньги'
    expect(page).to have_content '100 000 ₽'

    expect(page).to have_content '37'
    expect(page).to have_content '3'
    expect(page).to have_content '0 ₽'

    expect(page).to have_content '21'
    expect(page).to have_content 'в процессе'
    expect(page).to have_content '7'
    expect(page).to have_content '1 000 ₽'
  end
end
