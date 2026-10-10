"""Blackjack rounds under fixed rules."""


class ShoeEmpty(Exception):
    pass


class Shoe:
    def __init__(self, cards):
        self.cards = cards
        self.pos = 0

    def draw(self):
        if self.pos >= len(self.cards):
            raise ShoeEmpty
        card = self.cards[self.pos]
        self.pos += 1
        return card


def card_value(rank):
    return min(rank, 10)


def total(hand):
    """Return (total, is_soft)."""
    t = sum(card_value(c) for c in hand)
    if 1 in hand and t + 10 <= 21:
        return t + 10, True
    return t, False


def is_natural(hand):
    return len(hand) == 2 and total(hand)[0] == 21


def wants_card(hand, up):
    t, soft = total(hand)
    if t > 21:
        return False
    if soft:
        return t <= 17
    return t <= 11 or (t <= 16 and (up == 1 or up >= 7))


class Hand:
    def __init__(self, cards, stake):
        self.cards = cards
        self.stake = stake


def play_hand(hand, hands, bankroll, bet, up, shoe):
    t, soft = total(hand.cards)
    if len(hand.cards) == 2 and not soft and t in (10, 11) and 2 <= up <= 9:
        if bankroll >= sum(h.stake for h in hands) + bet:
            hand.stake *= 2
            hand.cards.append(shoe.draw())
            return
    while wants_card(hand.cards, up):
        hand.cards.append(shoe.draw())


def play_round(shoe, bankrolls, bets):
    """Play one round; return (bankroll changes, dealer_bust, naturals).

    Raises ShoeEmpty if the shoe runs out; nothing is changed in that case.
    """
    players = [i for i in range(len(bets)) if bankrolls[i] >= bets[i]]
    cards = {i: [shoe.draw()] for i in players}
    up = shoe.draw()
    for i in players:
        cards[i].append(shoe.draw())
    dealer = [up, shoe.draw()]

    delta = {i: 0 for i in players}
    naturals = [i for i in players if is_natural(cards[i])]

    if (up == 1 or card_value(up) == 10) and is_natural(dealer):
        for i in players:
            if i not in naturals:
                delta[i] -= bets[i]
        return delta, False, len(naturals)

    player_hands = {}
    for i in players:
        if i in naturals:
            delta[i] += bets[i] * 3 // 2
            continue
        bet = bets[i]
        first, second = cards[i]
        if first == second and first in (1, 8) and bankrolls[i] >= 2 * bet:
            h1, h2 = Hand([first], bet), Hand([second], bet)
            hands = [h1, h2]
            h1.cards.append(shoe.draw())
            h2.cards.append(shoe.draw())
            if first != 1:
                for h in hands:
                    play_hand(h, hands, bankrolls[i], bet, up, shoe)
        else:
            hands = [Hand(cards[i], bet)]
            play_hand(hands[0], hands, bankrolls[i], bet, up, shoe)
        player_hands[i] = hands

    live = any(total(h.cards)[0] <= 21 for hands in player_hands.values() for h in hands)
    if live:
        while total(dealer)[0] < 17:
            dealer.append(shoe.draw())
    dealer_total = total(dealer)[0]

    for i, hands in player_hands.items():
        for h in hands:
            t = total(h.cards)[0]
            if t > 21 or (dealer_total <= 21 and dealer_total > t):
                delta[i] -= h.stake
            elif dealer_total > 21 or dealer_total < t:
                delta[i] += h.stake
    return delta, dealer_total > 21, len(naturals)


def main(shoe, bankrolls, bets, rounds):
    shoe = Shoe(shoe)
    bankrolls = list(bankrolls)
    rounds_played = dealer_busts = naturals = 0
    for _ in range(rounds):
        if not any(b >= bet for b, bet in zip(bankrolls, bets)):
            break
        try:
            delta, bust, nat = play_round(shoe, bankrolls, bets)
        except ShoeEmpty:
            break
        for i, d in delta.items():
            bankrolls[i] += d
        rounds_played += 1
        dealer_busts += bust
        naturals += nat
    return bankrolls, rounds_played, dealer_busts, naturals
