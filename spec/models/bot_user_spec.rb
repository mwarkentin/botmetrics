RSpec.describe BotUser do
  describe 'associations' do
    it { is_expected.to belong_to :bot_instance }
    it { is_expected.to have_many :events }
  end

  describe 'validations' do
    subject { create :bot_user }

    it { is_expected.to validate_presence_of :uid }
    it { is_expected.to validate_presence_of :provider }
    it { is_expected.to validate_presence_of :bot_instance_id }
    it { is_expected.to validate_presence_of :membership_type }
    it { is_expected.to validate_uniqueness_of(:uid).scoped_to(:bot_instance_id) }

    it { is_expected.to allow_value('slack').for(:provider) }
    it { is_expected.to allow_value('kik').for(:provider) }
    it { is_expected.to allow_value('facebook').for(:provider) }
    it { is_expected.to allow_value('telegram').for(:provider) }
    it { is_expected.to_not allow_value('test').for(:provider) }
  end

  context 'scopes' do
    let!(:user)       { create(:user) }
    let!(:bot)        { create(:bot) }
    let!(:instance) { create(:bot_instance, :with_attributes, uid: '123', bot: bot) }

    let!(:bot_user_1) { create(:bot_user, bot_instance: instance, user_attributes: { nickname: 'john', email: 'john@example.com' }, last_interacted_with_bot_at: 5.days.ago, bot_interaction_count: 1) }
    let!(:bot_user_2) { create(:bot_user, bot_instance: instance, user_attributes: { nickname: 'sean', email: 'sean@example.com' }, last_interacted_with_bot_at: 2.days.ago, bot_interaction_count: 2) }

    describe '#user_attributes_eq' do
      it { expect(BotUser.user_attributes_eq(:nickname, 'john')).to eq [bot_user_1] }
    end

    describe '#user_attributes_contains' do
      it { expect(BotUser.user_attributes_cont(:nickname, 'an')).to eq [bot_user_2] }
    end

    describe '#interaction_count_eq' do
      it { expect(BotUser.interaction_count_eq(1)).to eq [bot_user_1] }
      it { expect(BotUser.interaction_count_eq(2)).to eq [bot_user_2] }
    end

    describe '#interaction_count_gt' do
      it { expect(BotUser.interaction_count_gt(1)).to eq [bot_user_2] }
      it { expect(BotUser.interaction_count_gt(2)).to eq [] }
    end

    describe '#interaction_count_betw' do
      it { expect(BotUser.interaction_count_betw(0, 1)).to eq [bot_user_1] }
      it { expect(BotUser.interaction_count_betw(0, 5)).to eq [bot_user_1, bot_user_2] }
    end

    describe '.user_signed_up_betw' do
      let(:one_week_user) { create(:bot_user, created_at: 7.days.ago) }
      it { expect(BotUser.user_signed_up_betw(8.days.ago, 5.days.ago)).to eq [one_week_user] }
    end

    describe '.user_signed_up_gt' do
      let(:one_week_user) { create(:bot_user, created_at: 7.days.ago) }

      it { expect(BotUser.user_signed_up_gt(5.days.ago)).to eq [one_week_user] }
    end

    describe '.user_signed_up_lt' do
      let(:one_week_user) { create(:bot_user, created_at: 7.days.ago) }

      it { expect(BotUser.user_signed_up_lt(5.days.ago)).to eq [bot_user_1, bot_user_2] }
    end
  end

  context 'interacted related scopes' do
    let(:timezone) { 'Pacific Time (US & Canada)' }

    before { travel_to Time.current }
    after { travel_back }

    let!(:user_1_id) { create(:bot_user, last_interacted_with_bot_at: 1.days.ago).id }
    let!(:user_2_id) { create(:bot_user, last_interacted_with_bot_at: 2.days.ago).id }
    let!(:user_3_id) { create(:bot_user, last_interacted_with_bot_at: 3.days.ago).id }
    let!(:user_4_id) { create(:bot_user, last_interacted_with_bot_at: 4.days.ago).id }
    let!(:user_5_id) { create(:bot_user, last_interacted_with_bot_at: 5.days.ago).id }

    describe '.interacted_at_betw' do
      it 'return users that interacted ago is within given range' do
        result = BotUser.interacted_at_betw(3.days.ago - 1.second, 3.days.ago + 1.second).map(&:id)

        expect(result).to match_array [user_3_id]
      end
    end

    describe '.interacted_at_lt' do
      it 'return users that interacted is lesser than given days ago' do
        result = BotUser.interacted_at_lt(3.days.ago).map(&:id)

        expect(result).to match_array [user_1_id, user_2_id]
      end
    end

    describe '.interacted_at_gt' do
      it 'return users that interacted is greater than given days ago' do
        result = BotUser.interacted_at_gt(3.days.ago).map(&:id)

        expect(result).to match_array [user_4_id, user_5_id]
      end
    end
  end

  context 'store accessors' do
    describe 'user_attributes' do
      it { expect(subject).to respond_to :nickname }
      it { expect(subject).to respond_to :email }
      it { expect(subject).to respond_to :full_name }
      it { expect(subject).to respond_to :first_name }
      it { expect(subject).to respond_to :last_name }
      it { expect(subject).to respond_to :gender }
    end
  end

  describe '.with_bot_instances' do
    let(:start_time) { Time.current.yesterday }
    let(:end_time)   { Time.current.tomorrow }

    it 'works' do
      bi = create :bot_instance
      bu = create :bot_user, bot_instance: bi
      create :bot_user

      users = BotUser.with_bot_instances(BotInstance.where(id: [bi.id]), bi.bot, start_time, end_time)

      expect(users.map(&:id)).to eq [bu.id]
    end
  end
end
