# encoding: UTF-8

require 'rails_helper'

describe GendImage do
  subject { FactoryGirl.create(:gend_image) }

  it { should validate_uniqueness_of :id_hash }

  it { should belong_to :src_image }

  it { should belong_to :user }

  it { should have_one :gend_thumb }

  it { should have_many :captions }

  it { should_not validate_presence_of :user }

  it 'should generate a unique id hash' do
    gend_image = FactoryGirl.create(:gend_image)
    expect(gend_image.id_hash).to_not be_nil
  end

  context 'setting fields derived from the image' do
    context 'when the image is not animated' do
      subject(:gend_image) { FactoryGirl.create(:gend_image) }

      specify { expect(gend_image.content_type).to eq('image/jpeg') }
      specify { expect(gend_image.height).to eq(399) }
      specify { expect(gend_image.width).to eq(399) }
      specify { expect(gend_image.size).to eq(9141) }
      specify { expect(gend_image.is_animated).to eq(false) }
    end

    context 'when the image is animated' do
      subject(:gend_image) { FactoryGirl.create(:animated_gend_image) }

      specify { expect(gend_image.is_animated).to eq(true) }
    end
  end

  describe '#ext' do
    let(:image) { File.read(Rails.root + 'spec/fixtures/files/ti_duck.jpg') }

    subject(:gend_image) do
      gend_image = GendImage.new(
        FactoryGirl.attributes_for(:gend_image, image: image)
      )
      gend_image.valid?
      gend_image
    end

    context 'jpg' do
      specify { expect(gend_image.format).to eq(:jpg) }
    end

    context 'gif' do
      let(:image) { File.read(Rails.root + 'spec/fixtures/files/omgcat.gif') }

      specify { expect(gend_image.format).to eq(:gif) }
    end

    context 'png' do
      let(:image) { File.read(Rails.root + 'spec/fixtures/files/ti_duck.png') }

      specify { expect(gend_image.format).to eq(:png) }
    end

    context 'other' do
      it 'returns nil for extension' do
        subject.content_type = 'foo/bar'
        expect(subject.format).to be_nil
      end
    end
  end

  describe '#email' do
    let(:gend_image) { FactoryGirl.create(:gend_image) }

    it 'passes validation when email is nil' do
      gend_image.email = nil
      expect(gend_image).to be_valid
    end

    it 'passes validation when email is the empty string' do
      gend_image.email = ''
      expect(gend_image).to be_valid
    end

    it 'fails validation when email is set' do
      gend_image.email = 'bot@bots.com'
      expect(gend_image).to_not be_valid
    end
  end

  describe '#create_jobs' do
    let(:gend_image) { FactoryGirl.create(:gend_image) }
    before do
      gend_image.src_image.size = src_image_size
      gend_image.src_image.save!
    end

    context 'when the image is small' do
      let(:src_image_size) { 51_200 }

      it 'puts the image in the small queue' do
        gend_image_process_job = instance_double(GendImageProcessJob)
        expect(GendImageProcessJob).to receive(:new).with(
          gend_image.id
        ).and_return(gend_image_process_job)
        expect(gend_image_process_job).to receive(:delay).with(
          queue: :gend_image_process_small
        ).and_return(gend_image_process_job)
        expect(gend_image_process_job).to receive(:perform)

        GendImage.set_callback(:commit, :after, :create_jobs)
        gend_image.run_callbacks(:commit)
        GendImage.skip_callback(:commit, :after, :create_jobs)
      end
    end

    context 'when the image is medium' do
      let(:src_image_size) { 575_488 }

      it 'puts the image in the small queue' do
        gend_image_process_job = instance_double(GendImageProcessJob)
        expect(GendImageProcessJob).to receive(:new).with(
          gend_image.id
        ).and_return(gend_image_process_job)
        expect(gend_image_process_job).to receive(:delay).with(
          queue: :gend_image_process_medium
        ).and_return(gend_image_process_job)
        expect(gend_image_process_job).to receive(:perform)

        GendImage.set_callback(:commit, :after, :create_jobs)
        gend_image.run_callbacks(:commit)
        GendImage.skip_callback(:commit, :after, :create_jobs)
      end
    end

    context 'when the image is large' do
      let(:src_image_size) { 5_767_168 }

      it 'puts the image in the small queue' do
        gend_image_process_job = instance_double(GendImageProcessJob)
        expect(GendImageProcessJob).to receive(:new).with(
          gend_image.id
        ).and_return(gend_image_process_job)
        expect(gend_image_process_job).to receive(:delay).with(
          queue: :gend_image_process_large
        ).and_return(gend_image_process_job)
        expect(gend_image_process_job).to receive(:perform)

        GendImage.set_callback(:commit, :after, :create_jobs)
        gend_image.run_callbacks(:commit)
        GendImage.skip_callback(:commit, :after, :create_jobs)
      end
    end

    context 'when the image is very large' do
      let(:src_image_size) { 10_485_761 }

      it 'puts the image in the small queue' do
        gend_image_process_job = instance_double(GendImageProcessJob)
        expect(GendImageProcessJob).to receive(:new).with(
          gend_image.id
        ).and_return(gend_image_process_job)
        expect(gend_image_process_job).to receive(:delay).with(
          queue: :gend_image_process_shitload
        ).and_return(
          gend_image_process_job
        )
        expect(gend_image_process_job).to receive(:perform)

        GendImage.set_callback(:commit, :after, :create_jobs)
        gend_image.run_callbacks(:commit)
        GendImage.skip_callback(:commit, :after, :create_jobs)
      end
    end
  end

  describe '.text_matches' do
    let(:caption1) { FactoryGirl.create(:caption, text: 'the quick brown fox') }
    let(:caption2) do
      FactoryGirl.create(:caption, text: 'jumped over the lazy dog')
    end
    before do
      @gend_image = FactoryGirl.create(
        :gend_image, captions: [caption1, caption2]
      )
    end

    context "when one of the image's captions matches" do
      it 'returns the matching image' do
        expect(GendImage.text_matches('fox')).to eq([@gend_image])
      end
    end

    context "when one of the image's captions matches case insensitive" do
      it 'returns the matching image' do
        expect(GendImage.text_matches('QuIcK')).to eq([@gend_image])
      end
    end

    context 'when there is whitespace in the query' do
      it 'still matches' do
        expect(GendImage.text_matches("jumped \t\r\n")).to eq([@gend_image])
      end
    end

    context "when none of the image's captions matches" do
      it 'returns no matches' do
        expect(GendImage.text_matches('no match')).to eq([])
      end
    end

    context 'when both of the captions match' do
      let(:caption1) do
        FactoryGirl.create(:caption, text: 'the quick brown fox')
      end
      let(:caption2) do
        FactoryGirl.create(:caption, text: 'jumped over the quick dog')
      end

      it 'returns only one match' do
        expect(GendImage.text_matches('quick')).to eq([@gend_image])
      end
    end
  end

  describe '#meme_text' do
    it 'returns the captions joined in position order' do
      gend_image = FactoryGirl.create(:gend_image)
      gend_image.captions.create(
        text: 'test 1', top_left_x_pct: 9, top_left_y_pct: 20,
        width_pct: 0.9, height_pct: 0.25
      )
      gend_image.captions.create(
        text: 'test 2', top_left_x_pct: 10, top_left_y_pct: 20,
        width_pct: 0.9, height_pct: 0.25
      )
      gend_image.captions.create(
        text: 'test 3', top_left_x_pct: 7, top_left_y_pct: 7,
        width_pct: 0.9, height_pct: 0.25
      )
      gend_image.save!
      expect(gend_image.meme_text).to eq('test 3 test 1 test 2')
    end
  end

  describe '.without_image' do
    it 'does not load the image data' do
      FactoryGirl.create(:gend_image)
      expect do
        GendImage.without_image.first.image
      end.to raise_error(ActiveModel::MissingAttributeError)
    end
  end

  describe '.publick' do
    it 'finds images that are not private' do
      gi1 = FactoryGirl.create(:gend_image, private: false)
      FactoryGirl.create(:gend_image, private: true)
      gi3 = FactoryGirl.create(:gend_image, private: false)
      expect(GendImage.publick).to contain_exactly(gi1, gi3)
    end
  end

  describe '.active' do
    it 'finds images that are not deleted' do
      FactoryGirl.create(:gend_image, is_deleted: true)
      gi2 = FactoryGirl.create(:gend_image, is_deleted: false)
      FactoryGirl.create(:gend_image, is_deleted: true)
      expect(GendImage.active).to contain_exactly(gi2)
    end
  end

  describe '.finished' do
    it 'finds images that are not in progress' do
      FactoryGirl.create(:gend_image, work_in_progress: true)
      gi2 = FactoryGirl.create(:gend_image, work_in_progress: false)
      gi3 = FactoryGirl.create(:gend_image, work_in_progress: false)
      expect(GendImage.finished).to contain_exactly(gi2, gi3)
    end
  end

  describe '.most_recent' do
    it 'order the images by most used' do
      gi1 = FactoryGirl.create(:gend_image)
      gi2 = FactoryGirl.create(:gend_image)
      gi2.update!(updated_at: Time.now + 1)
      gi3 = FactoryGirl.create(:gend_image)
      gi3.update!(updated_at: Time.now + 2)

      expect(GendImage.most_recent(3)).to eq([gi3, gi2, gi1])
    end
  end

  describe '.for_user' do
    let(:relation) { double(ActiveRecord::Relation) }
    let(:result) { double(ActiveRecord::Relation) }

    context 'when the user is nil' do
      let(:user) { nil }

      it 'returns images that are not private, deleted or in progress' do
        expect(GendImage).to receive(:without_image).and_return(relation)
        expect(relation).to receive(:includes).with(:gend_thumb).and_return(
          relation
        )
        expect(relation).to receive(:text_matches).with('query').and_return(
          relation
        )
        expect(relation).to receive(:publick).and_return(relation)
        expect(relation).to receive(:active).and_return(relation)
        expect(relation).to receive(:finished).and_return(relation)
        expect(relation).to receive(:most_recent).and_return(relation)
        expect(relation).to receive(:page).with(1).and_return(result)
        expect(GendImage.for_user(user, 'query', 1)).to eq(result)
      end
    end

    context 'when the user is not an admin user' do
      let(:user) { FactoryGirl.create(:user) }

      it 'returns images that are not private, deleted or in progress' do
        expect(GendImage).to receive(:without_image).and_return(relation)
        expect(relation).to receive(:includes).with(:gend_thumb).and_return(
          relation
        )
        expect(relation).to receive(:text_matches).with('query').and_return(
          relation
        )
        expect(relation).to receive(:publick).and_return(relation)
        expect(relation).to receive(:active).and_return(relation)
        expect(relation).to receive(:finished).and_return(relation)
        expect(relation).to receive(:most_recent).and_return(relation)
        expect(relation).to receive(:page).with(1).and_return(result)
        expect(GendImage.for_user(user, 'query', 1)).to eq(result)
      end
    end

    context 'when the user is an admin user' do
      let(:user) { FactoryGirl.create(:admin_user) }

      it 'returns all images' do
        expect(GendImage).to receive(:without_image).and_return(relation)
        expect(relation).to receive(:includes).with(:gend_thumb).and_return(
          relation
        )
        expect(relation).to receive(:text_matches).with('query').and_return(
          relation
        )
        expect(relation).to receive(:most_recent).and_return(relation)
        expect(relation).to receive(:page).with(1).and_return(result)
        expect(GendImage.for_user(user, 'query', 1)).to eq(result)
      end
    end
  end

  describe '#dimensions' do
    it 'returns widthxheight' do
      gend_image = FactoryGirl.create(:gend_image)
      gend_image.set_derived_image_fields
      expect(gend_image.dimensions).to eq('399x399')
    end
  end

  describe '#headers' do
    subject(:gend_image) { FactoryGirl.create(:finished_gend_image) }

    it 'has the content length' do
      expect(gend_image.headers).to include('Content-Length' => 9141)
    end

    it 'has the content type' do
      expect(gend_image.headers).to include('Content-Type' => 'image/jpeg')
    end
  end

  describe '#image_url' do
    it 'has a getter and setter' do
      gend_image = FactoryGirl.create(:finished_gend_image)
      url = 'http://test.host/gend_images/test.jpg'
      gend_image.image_url = url
      expect(gend_image.image_url).to eq(url)
    end
  end

  describe '#thumbnail_url' do
    it 'has a getter and setter' do
      gend_image = FactoryGirl.create(:finished_gend_image)
      url = 'http://test.host/gend_thumbs/12345.jpg'
      gend_image.thumbnail_url = url
      expect(gend_image.thumbnail_url).to eq(url)
    end
  end

  describe 'setting the search document' do
    let(:caption1) do
      FactoryGirl.create(:caption, text: 'abc', top_left_y_pct: 0.10)
    end
    let(:caption2) do
      FactoryGirl.create(:caption, text: 'def', top_left_y_pct: 0.20)
    end
    let(:gend_image) do
      FactoryGirl.create(:finished_gend_image, captions: [caption1, caption2])
    end

    it 'sets the search document' do
      expect(gend_image.search_document).to eq(
        "abc def src image name #{gend_image.id_hash}"
      )
    end

    context 'when there is leading whitespace' do
      let(:caption1) do
        FactoryGirl.create(:caption, text: '  abc', top_left_y_pct: 0.10)
      end
      it 'strips the whitespace' do
        expect(gend_image.search_document).to eq(
          "abc def src image name #{gend_image.id_hash}"
        )
      end
    end
  end

  describe '.searchable_columns' do
    it 'is the search_document' do
      expect(GendImage.searchable_columns).to eq([:search_document])
    end
  end
end
