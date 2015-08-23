require 'rails_helper'

describe GendImageProcessJob do
  subject(:gend_image_process_job) { GendImageProcessJob.new(gend_image.id) }
  let(:gend_image) { FactoryGirl.create(:gend_image, image: nil) }

  it 'generates the meme image' do
    gend_image_process_job.perform
    gend_image.reload
    expect(gend_image.magick_image_list.columns).to eq(399)
    expect(gend_image.magick_image_list.rows).to eq(399)
  end

  it 'generates a thumbnail' do
    gend_image_process_job.perform
    expect(gend_image.gend_thumb).not_to be_nil
    expect(gend_image.gend_thumb.width).to eq(
      MemeCaptainWeb::Config::THUMB_SIDE)
    expect(gend_image.gend_thumb.height).to eq(
      MemeCaptainWeb::Config::THUMB_SIDE)
  end

  it 'marks the gend image as finished' do
    expect do
      gend_image_process_job.perform
      gend_image.reload
    end.to change { gend_image.work_in_progress }.from(true).to(false)
  end
end
