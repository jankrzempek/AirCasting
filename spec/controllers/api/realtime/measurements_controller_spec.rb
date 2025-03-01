require 'rails_helper'

describe Api::Realtime::MeasurementsController do
  describe 'POST #create' do
    subject { post :create, params: { data: data } }

    let(:user) { FactoryBot.create(:user) }
    let(:session_uuid) { '36cfd811-dc1b-430f-a647-bfc88921bf4c' }
    let(:value) { 1.23 }
    let(:data) do
      {
        measurement_type: "Sound Level",
        measurements: [{
          longitude: 25.4356212,
          latitude: 56.4523456,
          time: "2016-05-11T17:09:02",
          milliseconds: 925,
          measured_value: 59.15683475380729,
          value: value
        }],
        sensor_package_name: "Builtin",
        sensor_name: "Phone Microphone",
        session_uuid: session_uuid,
        measurement_short_type: "dB",
        unit_symbol: "dB",
        threshold_high: 80,
        threshold_low: 60,
        threshold_medium: 70,
        threshold_very_high: 100,
        threshold_very_low: 20,
        unit_name: "decibels"
      }.to_json
    end

    before { sign_in(user) }

    context 'when the session with requested `uuid` and `user` exists' do
      before do
        FactoryBot.create(:fixed_session, user: user, uuid: session_uuid)
      end

      it 'returns `success`' do
        subject
        expect(response.status).to eq(200)
      end

      it 'creates stream' do
        expect { subject }.to change(Stream, :count).by(1)
        expect(Stream.first.attributes).to include(
          'max_latitude' => 56.4523456,
          'min_latitude' => 56.4523456,
          'min_longitude' => 25.4356212,
          'max_longitude' => 25.4356212
        )
      end

      it 'updates stream.average_value' do
        subject

        expect(Stream.first.average_value).to eq(value)
      end

      it 'creates measurement' do
        expect_any_instance_of(MeasurementsCreator).to receive(:call).once
        subject
      end
    end

    context 'when the session with requested `uuid` does not exist' do
      before do
        FactoryBot.create(
          :fixed_session,
          user: user,
          uuid: 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
        )
      end

      it 'returns `bad request`' do
        subject
        expect(response.status).to eq(400)
      end

      it 'does not create stream' do
        expect { subject }.to_not change(Stream, :count)
      end
    end
  end
end
