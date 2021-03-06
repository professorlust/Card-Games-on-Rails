require 'spec_helper'

describe Round do

  before do
    @game = FactoryGirl.create(:game)
    @player1 = FactoryGirl.create(:player, :game_id => @game.id, :seat => 0)
    @player2 = FactoryGirl.create(:player, :game_id => @game.id, :seat => 1)
    @player3 = FactoryGirl.create(:player, :game_id => @game.id, :seat => 2)
    @player4 = FactoryGirl.create(:player, :game_id => @game.id, :seat => 3)
    create_cards
    @round = FactoryGirl.create(:round, :game_id => @game.id, :dealer_id => @player1.id)
  end

  describe "#setup" do

    context "#new_round" do

      it "should show that round has been initiated" do
        @round.should be_an_instance_of Round
      end

      it "should know it's game parent" do
        @round.game.should == @game
      end

      it "should know it's player" do
        @round.players.length.should == 4
        @round.players.include?(@player1).should == true
      end

      it "should know who the dealer is" do
        @round.dealer.should == @player1
      end
      
      it "should know that hearts haven't been broken yet" do
        @round.hearts_broken.should == false
      end
      
    end

  end

  describe "#methods" do
    
    context "create_tricks" do

      it "should increase Tricks by 1" do
        expect{ @round.create_trick }.to change{ Trick.count }.by(1)
      end
    end
    
    context "previous_trick" do
      
      before do
        @trick1 = FactoryGirl.create(:trick, :round_id => @round.id)
        @trick2 = FactoryGirl.create(:trick, :round_id => @round.id)
        @trick3 = FactoryGirl.create(:trick, :round_id => @round.id)
      end
      
      it "should know the correct trick" do
        @round.previous_trick.should == @trick2
        @trick4 = FactoryGirl.create(:trick, :round_id => @round.id)
        @round.previous_trick.should == @trick3
      end
    end
    
    context "deal_cards" do
      
      it "should have dealt 13 cards to every player on round creation" do
        @round.players.each do |player|
          player.hand.length.should == 13
        end
      end
    end
    
    context "pass_cards" do
      
      before do
        @round.fill_computer_passing_sets
      end
      
      it "should not crash" do
        @round.pass_cards(:left)
      end
      
      it "should pass 3 cards to the left" do
        current_1_hand = [] + @player1.hand
        current_2_hand = [] + @player2.hand
        @round.pass_cards(:left)
        new_cards = 0
        @player2.reload.hand.each do |card|
          if !current_2_hand.include?(card)
            new_cards += 1
            current_1_hand.should include(card)
          end
        end
        new_cards.should == 3
      end
      
      it "should pass 3 cards to the right" do
        current_1_hand = [] + @player1.hand
        current_4_hand = [] + @player4.hand
        @round.pass_cards(:right)
        new_cards = 0
        @player4.reload.hand.each do |card|
          if !current_4_hand.include?(card)
            new_cards += 1
            current_1_hand.should include(card)
          end
        end
        new_cards.should == 3
      end
        
      it "should pass 3 cards across" do
        current_1_hand = [] + @player1.hand
        current_3_hand = [] + @player3.hand
        @round.pass_cards(:across)
        new_cards = 0
        @player3.reload.hand.each do |card|
          if !current_3_hand.include?(card)
            new_cards += 1
            current_1_hand.should include(card)
          end
        end
        new_cards.should == 3
      end
      
      it "should not pass any cards for none" do
        current_1_hand = [] + @player1.hand
        @round.pass_cards(:none)
        new_cards = 0
        @player1.reload.hand.each do |card|
          new_cards += 1 unless current_1_hand.include?(card)
        end
        new_cards.should == 0
      end
    end
    
    context "two_of_clubs_owner" do
      
      it "should correctly find a Player" do
        @round.send(:two_of_clubs_owner).should be_an_instance_of Player
      end
      
      it "should find the correct Player" do
        @round.players.each{|p| p.hand.each{|c| c.destroy}}
        two_club = Card.create(:value => "2", :suit => "club")
        pc = PlayerCard.create(:player_id => @player1.id, :card_id => two_club.id)
        @round.send(:two_of_clubs_owner).should == @player1
        pc.update_attributes(:player_id => @player2.id)
        @round.send(:two_of_clubs_owner).should == @player2
      end      
    end
    
    context "get_new_leader" do
      
      it "should find the two of clubs owner without any tricks played" do
        two_club = Card.create(:value => "2", :suit => "club")
        pc = PlayerCard.create(:player_id => @player1.id, :card_id => two_club.id)
        @round.get_new_leader.should == @player1
      end
      
      it "should find last trick winner when trick(s) have been played" do
        first_trick = double("my first trick")
        trick = double("my trick")
        trick.stub(:trick_winner).and_return(@player4)
        @round.stub(:tricks).and_return([first_trick, trick])
        @round.get_new_leader.should == @player4
      end
    end
    
    context "pass_direction(position)" do
      
      it "should return :left for positions 0, 4, 8" do
        @round.pass_direction(0).should == :left
        @round.pass_direction(4).should == :left
        @round.pass_direction(8).should == :left
      end
      
      it "should return :right for positions 1, 5 ,9" do
        @round.pass_direction(1).should == :right
        @round.pass_direction(5).should == :right
        @round.pass_direction(9).should == :right
      end
      
      it "should return :across for positions 2, 6, 10" do
        @round.pass_direction(2).should == :across
        @round.pass_direction(6).should == :across
        @round.pass_direction(10).should == :across
      end
      
      it "should return :none for positions 3, 7, 11" do
        @round.pass_direction(3).should == :none
        @round.pass_direction(7).should == :none
        @round.pass_direction(11).should == :none
      end
    end
  
  end
  
  describe "#situations" do
    
    context "passing_time?" do
      
      it "should be passing_time? since trick has just started" do
        @round.passing_time?.should == true
      end
      
      it "should not be passing_time? after cards are passed" do
        @round.pass_cards
        @round.passing_time?.should == false
      end
      
      it "should not be passing_time? if direction == :none" do
        @round.update_attributes(:position => 3)
        @round.passing_time?.should == false
      end
    end
    
    context "has_an_active_trick?" do
      
      it "should be false as a new round" do
        @round.has_an_active_trick?.should == false
      end
      
      it "should be true if it has a trick that isn't over" do
        FactoryGirl.create(:trick, :round_id => @round.id)
        @round.has_an_active_trick?.should == true
      end
      
      it "should be false if it has a trick that is over" do
        fake_last_trick = double("my last trick")
        @round.stub(:last_trick).and_return(fake_last_trick)
        fake_last_trick.stub(:is_not_over?).and_return(false)
        @round.has_an_active_trick?.should == false
      end
    end
    
    context "is_ready_for_a_new_trick?" do
      
      it "should return false for a new round (round has_not_started)" do
        @round.is_ready_for_a_new_trick?.should == false
      end
      
      it "should return true if cards are passed and no tricks exist" do
        @round.pass_cards
        @round.is_ready_for_a_new_trick?.should == true
      end
      
      it "should return true if tricks exist and last trick is over" do
        2.times { FactoryGirl.create(:trick, :round_id => @round.id) }
        fake_last_trick = double("my last trick")
        @round.stub(:last_trick).and_return(fake_last_trick)
        fake_last_trick.stub(:is_over?).and_return(true)
        @round.is_ready_for_a_new_trick?.should == true
      end
      
      it "should return false if tricks exist and last trick is not over" do
        2.times { FactoryGirl.create(:trick, :round_id => @round.id) }
        fake_last_trick = double("my last trick")
        @round.stub(:last_trick).and_return(fake_last_trick)
        fake_last_trick.stub(:is_over?).and_return(false)
        @round.is_ready_for_a_new_trick?.should == false        
      end
    end
    
    context "is_over?" do
      
      it "should return false for a new round" do
        @round.is_over?.should == false
      end
      
      it "should return false if 13 tricks exist, but last one isn't over" do
        13.times { FactoryGirl.create(:trick, :round_id => @round.id) }
        fake_last_trick = double("my last trick")
        @round.stub(:last_trick).and_return(fake_last_trick)
        fake_last_trick.stub(:is_over?).and_return(false)
        @round.is_over?.should == false
      end
      
      it "should return true if 13 tricks exist, and last one is over" do
        13.times { FactoryGirl.create(:trick, :round_id => @round.id) }
        fake_last_trick = double("my last trick")
        @round.stub(:last_trick).and_return(fake_last_trick)
        fake_last_trick.stub(:is_over?).and_return(true)        
        @round.is_over?.should == true
      end
    end
    
  end
  
  describe "#round_play" do
      
    context "making new tricks" do
      
      it "should increment trick count of the round" do
        expect{ Trick.create(:round_id => @round.id, :leader_id => @player1.id, :position => 0) }.to change{ @round.tricks(true).length }.by(1)
      end
      
      it "should assign appropriate position to a new trick" do
        trick1 = Trick.create(:round_id => @round.id, :leader_id => @player1.id, :position => @round.tricks_played); @round.reload
        trick2 = Trick.create(:round_id => @round.id, :leader_id => @player1.id, :position => @round.tricks_played); @round.reload
        trick3 = Trick.create(:round_id => @round.id, :leader_id => @player1.id, :position => @round.tricks_played); @round.reload
        trick1.position.should == 0
        trick2.position.should == 1
        trick3.position.should == 2
      end
    end
    
  end
  
  describe "#round_scoring" do
    
    context "shared_round" do
      
      before do
        @pr1 = FactoryGirl.create(:player_round, :player_id => @player1.id, :round_id => @round.id)
        @pr2 = FactoryGirl.create(:player_round, :player_id => @player2.id, :round_id => @round.id)
        @pr3 = FactoryGirl.create(:player_round, :player_id => @player3.id, :round_id => @round.id)
        @pr4 = FactoryGirl.create(:player_round, :player_id => @player4.id, :round_id => @round.id)
        
        first_trick = double("first trick")
        second_trick = double("second trick")
        third_trick = double("third trick")
        fourth_trick = double("fourth trick")
        
        first_trick.stub(:trick_winner).and_return(@player1)
        second_trick.stub(:trick_winner).and_return(@player2)
        third_trick.stub(:trick_winner).and_return(@player3)
        fourth_trick.stub(:trick_winner).and_return(@player4)
        
        first_trick.stub(:trick_score).and_return(10)
        second_trick.stub(:trick_score).and_return(3)
        third_trick.stub(:trick_score).and_return(10)
        fourth_trick.stub(:trick_score).and_return(3)
        
        @round.stub(:tricks).and_return([first_trick, second_trick, third_trick, fourth_trick])
      end
      
      it "should calculate round score to total 26" do
        @round.calculate_round_scores
        all_round_scores = 0
        @round.player_rounds.each {|pr| all_round_scores += pr.reload.round_score }
        all_round_scores.should == 26
      end
    end
    
  end
  
  describe "#total_scoring" do
    
    context "during a regular round" do
      
      before do
        @pr1 = FactoryGirl.create(:player_round, :player_id => @player1.id, :round_id => @round.id, :round_score => 3)
        @pr2 = FactoryGirl.create(:player_round, :player_id => @player2.id, :round_id => @round.id, :round_score => 6)
        @pr3 = FactoryGirl.create(:player_round, :player_id => @player3.id, :round_id => @round.id, :round_score => 10)
        @pr4 = FactoryGirl.create(:player_round, :player_id => @player4.id, :round_id => @round.id, :round_score => 7)
      end
      
      it "should update players total_scores appropriately" do
        @round.update_total_scores
        @player1.reload.total_score.should == 3
        @player2.reload.total_score.should == 6
        @player3.reload.total_score.should == 10
        @player4.reload.total_score.should == 7
      end
    end
    
    context "during a swept round" do
      
      before do
        @pr1 = FactoryGirl.create(:player_round, :player_id => @player1.id, :round_id => @round.id, :round_score => 0)
        @pr2 = FactoryGirl.create(:player_round, :player_id => @player2.id, :round_id => @round.id, :round_score => 26)
        @pr3 = FactoryGirl.create(:player_round, :player_id => @player3.id, :round_id => @round.id, :round_score => 0)
        @pr4 = FactoryGirl.create(:player_round, :player_id => @player4.id, :round_id => @round.id, :round_score => 0)
      end
      
      it "should acknowledge the moon shooting" do
        @round.update_total_scores
        @player1.reload.total_score.should == 26
        @player2.reload.total_score.should == 0
        @player3.reload.total_score.should == 26
        @player4.reload.total_score.should == 26
      end
    end
  end

end