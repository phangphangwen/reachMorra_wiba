'reach 0.1';

// create enum for results
const [ isResult, NO_WINS, A_WINS, B_WINS, DRAW,  ] = makeEnum(4);

// 0 = none, 1 = B wins, 2 = draw , 3 = A wins
const winner = (handApple, guessApple, handJoe, guessJoe) => {
  const total = handApple + handJoe;

  if ( guessApple == total && guessJoe == total  ) {
      return DRAW    // draw
  }  else if ( guessJoe == total) {
      return B_WINS  // Joe wins
  }
  else if ( guessApple == total ) { 
      return A_WINS  // Apple wins
  } else {
      return NO_WINS  // else no one wins
  }
 
}
  
assert(winner(1,2,1,3 ) == A_WINS);
assert(winner(5,10,5,8 ) == A_WINS);

assert(winner(3,6,4,7 ) == B_WINS);
assert(winner(1,5,3,4 ) == B_WINS);

assert(winner(0,0,0,0 ) == DRAW);
assert(winner(2,4,2,4 ) == DRAW);
assert(winner(5,10,5,10 ) == DRAW);

assert(winner(3,6,2,4 ) == NO_WINS);
assert(winner(0,3,1,5 ) == NO_WINS);

forall(UInt, handApple =>
  forall(UInt, handJoe =>
    forall(UInt, guessApple =>
      forall(UInt, guessJoe =>
    assert(isResult(winner(handApple, guessApple, handJoe , guessJoe)))
))));


// Here to Setup common functions
const commonInteract = {
  ...hasRandom,
  reportResult: Fun([UInt], Null),
  reportHands: Fun([UInt, UInt, UInt, UInt], Null),
  informTimeout: Fun([], Null),
  getHand: Fun([], UInt),
  getGuess: Fun([], UInt),
};

const appleInterect = {
  ...commonInteract,
  wager: UInt, 
  deadline: UInt, 
}

const joeInteract = {
  ...commonInteract,
  acceptWager: Fun([UInt], Null),
}


export const main = Reach.App(() => {
  const Apple = Participant('Apple',appleInterect );
  const Joe = Participant('Joe', joeInteract );
  init();

  // Check for timeouts
  const informTimeout = () => {
    each([Apple, Joe], () => {
      interact.informTimeout();
    });
  };

  Apple.only(() => {
    const wager = declassify(interact.wager);
    const deadline = declassify(interact.deadline);
  });
  Apple.publish(wager, deadline)
    .pay(wager);
  commit();

  Joe.only(() => {
    interact.acceptWager(wager);
  });
  Joe.pay(wager)
    .timeout(relativeTime(deadline), () => closeTo(Apple, informTimeout));
  

  var result = DRAW;
   invariant( balance() == 2 * wager && isResult(result) );

   while ( result == DRAW || result == NO_WINS ) {
    commit();

  Apple.only(() => {
    const _handApple = interact.getHand();
    const [_commitApple1, _saltApple1] = makeCommitment(interact, _handApple);
    const commitApple1 = declassify(_commitApple1);

    const _guessApple = interact.getGuess();
    const [_commitApple2, _saltApple2] = makeCommitment(interact, _guessApple);
    const commitApple2 = declassify(_commitApple2);

  })
  

  Apple.publish(commitApple1, commitApple2)
      .timeout(relativeTime(deadline), () => closeTo(Joe, informTimeout));
    commit();


    unknowable(Joe, Apple(_handApple,_guessApple, _saltApple1,_saltApple2 ));
  
  Joe.only(() => {
    const handJoe = declassify(interact.getHand());
    const guessJoe = declassify(interact.getGuess());
  });

  Joe.publish(handJoe, guessJoe)
    .timeout(relativeTime(deadline), () => closeTo(Apple, informTimeout));
  commit();

  Apple.only(() => {
    const saltApple1 = declassify(_saltApple1);
    const handApple = declassify(_handApple);
    const saltApple2 = declassify(_saltApple2);
    const guessApple = declassify(_guessApple);

  });

  Apple.publish(saltApple1,saltApple2, handApple, guessApple)
    .timeout(relativeTime(deadline), () => closeTo(Joe, informTimeout));
  checkCommitment(commitApple1, saltApple1, handApple);
  checkCommitment(commitApple2, saltApple2, guessApple);

  // Report results to all participants
  each([Apple, Joe], () => {
    interact.reportHands(handApple, guessApple, handJoe, guessJoe);
  });

  result = winner(handApple, guessApple, handJoe, guessJoe);
  continue;
}


assert(result == A_WINS || result == B_WINS);

each([Apple, Joe], () => {
  interact.reportResult(result);
});

transfer(2 * wager).to(result == A_WINS ? Apple : Joe);
commit();

});
