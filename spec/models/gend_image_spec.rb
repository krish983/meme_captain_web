# encoding: UTF-8

require 'spec_helper'

describe GendImage do

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
      subject(:gend_image) do
        gend_image = GendImage.new(FactoryGirl.attributes_for(:gend_image))
        gend_image.valid?
        gend_image
      end

      its(:content_type) { should == 'image/jpeg' }
      its(:height) { should == 399 }
      its(:width) { should == 399 }
      its(:size) { should == 9141 }
      its(:is_animated) { should eq(false) }
    end

    context 'when the image is animated' do
      subject(:gend_image) do
        gend_image = GendImage.new(
            FactoryGirl.attributes_for(
                :gend_image,
                image: File.read(
                    Rails.root + 'spec/fixtures/files/omgcat.gif')))
        gend_image.valid?
        gend_image
      end

      its(:is_animated) { should eq(true) }
    end

  end

  it 'generates a thumbnail'
  # figure out how to use run a delayed job in spec

  describe '#ext' do

    let(:image) { File.read(Rails.root + 'spec/fixtures/files/ti_duck.jpg') }

    subject do
      gend_image = GendImage.new(
          FactoryGirl.attributes_for(:gend_image, image: image))
      gend_image.valid?
      gend_image
    end

    context 'jpg' do
      its(:format) { should == :jpg }
    end

    context 'gif' do
      let(:image) { File.read(Rails.root + 'spec/fixtures/files/omgcat.gif') }

      its(:format) { should == :gif }
    end

    context 'png' do
      let(:image) { File.read(Rails.root + 'spec/fixtures/files/ti_duck.png') }

      its(:format) { should == :png }
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

end
