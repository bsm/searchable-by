require 'spec_helper'

describe SearchableBy::Util do
  context 'with norm_values' do
    def norm(str, **opts)
      described_class.norm_values(str, **opts).each_with_object({}) do |val, acc|
        acc[val.term] = val.negate
      end
    end

    it 'tokenises strings' do
      expect(norm(nil)).to eq({})
      expect(norm('""')).to eq({})
      expect(norm('-+""')).to eq({})
      expect(norm('simple words')).to eq('simple' => false, 'words' => false)
      expect(norm(" with   \t spaces\n")).to eq('with' => false, 'spaces' => false)
      expect(norm('with with duplicates with')).to eq('with' => false, 'duplicates' => false)
      expect(norm('with "full term"')).to eq('full term' => false, 'with' => false)
      expect(norm('"""odd double quotes around"""')).to eq('odd double quotes around' => false)
      expect(norm('""even double quotes around""')).to eq('even double quotes around' => false)
      expect(norm('with\'apostrophe')).to eq("with'apostrophe" => false)
      expect(norm('with -minus')).to eq('minus' => true, 'with' => false)
      expect(norm('with +plus')).to eq('plus' => false, 'with' => false)
      expect(norm('with-minus')).to eq('with-minus' => false)
      expect(norm('with+plus')).to eq('with+plus' => false)
      expect(norm('with -"minus before"')).to eq('minus before' => true, 'with' => false)
      expect(norm('with "-minus within"')).to eq('-minus within' => false, 'with' => false)
      expect(norm('with +"plus before"')).to eq('plus before' => false, 'with' => false)
      expect(norm('with "+plus within"')).to eq('+plus within' => false, 'with' => false)
      expect(norm('+plus "in other term"')).to eq('in other term' => false, 'plus' => false)
      expect(norm('with_blank \'\'')).to eq('with_blank' => false, '\'\'' => false)
      expect(norm('with_blank_doubles ""')).to eq('with_blank_doubles' => false)
      expect(norm('with min length', min_length: 4)).to eq('length' => false, 'with' => false)
    end
  end
end
