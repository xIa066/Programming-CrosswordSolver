% ============================================================================== 
% Author: Zexi Liu
% Student Number: 813212
% Email: zexil1@student.unimelb.edu.au

% the Implementation of Project 2 in COMP90048 Declarative Programming, 2020 
% Semester1.

% Motivation:
% 1. the problem is a fill−in puzzle problem. The puzzle consisits of a
% grid of squares, most of which are most of which are empty, into which letters 
% or digits are to be written, but some of which are filled in solid, and are n− 
% ot to be written in. You are also given a list of words to place in the puzzle

% 2. This file implemented Predicate, puzzle_solution(+Puzzle, +WordList), that 
% holds when Puzzle is the the representation of a solved fillin puzzle for the 
% given list of words, WordList.

% Strategy:
% 1. transform the fill−in Puzzle problem into a problem that matches WorldList 
% with a list of empty slots of the Puzzle (Row by row). To make sure the words 
% are corectly filled, the transpose of the puzzle is taken to verify vertically
% 2. take advantage of prolog logical variable, where the predicate does not ho− 
% ld when the unificattion suceed. This can be used to make sure make sure that 
% the same variable is used for the same square, whether it appears in a vertic− 
% al or horizontal slot, then Prolog will ensure that the letter placed in the 
% box for a horizontal word is the same as for an intersecting vertical word.
% 3. to reduce computation time complexity for larger puzzle, Each time a word 
% is to be placed, it counts the number of words that match each slot, and
% select (one of) the slot(s) with the fewest matching words to fill. This
% minimises the search space.

% Structure of the program:
% 1. puzzle_solution(+Puzzle, +WordList). consists of two predicate:

% 2. change_problem(+Puzzle, −UnfilledSlots). where it changes the represen−
% tation of the puzzle problem itself. Transpose of Puzzle has been taken, empty 
% slots are extracted row by row from horizontal and vertical. Finally return a 
% new representation of the problem, UnfilledSlots

% 3. Then simply fill the WorldList into the new representation (Unfilled Slots) 
% But a count fewest sucess mechanism is implemented to minmize the search space
% Declaration: I have made some changes of my codes based on an existing repo in
% github through researching, But that was only for the debugging purpose in 
% the late stage of development. By using this coding styles, I solved the
% infinite loop problems that keep occuring in my original copy. I believe the 
% originality of my work can be proved in my persistent submissions history
% on Grok and different wireframe structure of the puzzle_solution/2 predicate
% the reference link:
% https://github.com/threethousandmonkeys/FillingPuzzle/blob/master/proj2.pl
% ============================================================================== 
% imported library, clpfd:
% library clpfd contains transpose/2 predicates,
% which can be found in the following link,
% https://www.swi−prolog.org/pack/file_details/xlibrary/prolog/transpose.pl?show
% =src
:− ensure_loaded(library(clpfd)).
% ============================================================================== 
%   puzzle_solution(+Puzzle, +WordList).
%   Puzzle: a list of a list to represent a square matrix
%   WordList: a list of words, that are no greater than the size of matrix

puzzle_solution(Puzzle, WordList) :−
  % change the representation of the problem
  change_problem(Puzzle, UnfilledSlots),
  % fill the World into the new representation (Unfilled Slots)
  fill(UnfilledSlots, WordList).

% ============================================================================== 
%   change_problem(+Puzzle, −UnfilledSlots).
%   Puzzle: a list of rows (a list) to represent a square matrix
%   UnfilledSlots: a list of slots (a list)

change_problem(Puzzle, UnfilledSlots):− 
  transpose(Puzzle, PuzzleT),
  append(Puzzle,PuzzleT, PuzzleAUG),
  construct_slots(PuzzleAUG,[],UnfilledSlots).

% ==============================================================================
%   construct_slots(+PuzzleAug, +L, ?UnffiledSlots)
%   PuzzleAug: a list of rows (a list), however it augments transpose puzzle
%   L: a list used to initialize/update UnfilledSlots in recursive calls 
%   UnfilledSlots: a list of slots (a list) (Output)

% Base case where rows are scanned till the end
construct_slots([], L, L).

% Recursive case, handling each row
construct_slots([Row|Rows],L, UnfilledSlots):−

  % group the (_) characters as a slot, and append to L and UnfilledSlots
  group_underscore(Row, [], L, NewUnfilledSlots),
  
  % tail recursion
  construct_slots(Rows, NewUnfilledSlots, UnfilledSlots).

% ==============================================================================
%   group_underscore(+PuzzleRow, +SlidingWindow, +L, ?UnffiledSlots)
%   PuzzleRow: a row(list) of character, either ’#’ or ’_’
%   SlidingWindow: an appending list used to capture groupped ’−’
%   L: updated by SlidingWindow when groupped ’−’ meet either ’#’ or last Char
%   UnfilledSlot: updated by L once each all Char are scanned

% Base case: when it scanned till the end of char
group_underscore([], Window, L, UnfilledSlots):− 
  ( Window == []
  −>  % initialize UnfilledSlots
      UnfilledSlots = L
  ; (length(Window, LenWindow), LenWindow > 1
    −>  append(L, [Window],NewL),
        % initialize the UnfilledSlots with NewL!
        UnfilledSlots = NewL 
        ; UnfilledSlots = L
        )
  ).

% recursive case: checking each Char
group_underscore([Char|Tail], Window, L, UnfilledSlots):− 
  ( Char == ’#’
  −>  % wrap up the window and add it to L 
      (Window == []
      −>
        group_underscore(Tail, [], L, UnfilledSlots)
      ; (length(Window,LenWindow), LenWindow > 1
        −>
          append(L,[Window], NewL),
          group_underscore(Tail, [], NewL, UnfilledSlots)
        ;
          group_underscore(Tail, [], L,UnfilledSlots)
        )
      )
    ; % when Char is (_)
      append(Window,[Char], NewWindow),
      % Update Window
      group_underscore(Tail, NewWindow, L, UnfilledSlots)
    ).

% ============================================================================== 
% fill(+UnfilledSlots, +WordList).

fill([],_).

fill([Slot|Slots],WordList):−

  % initialize the can_fill succeses of the slot
  count_successes(Slot, WordList,0,Successes),
  
  % recursive compare successes of the slot with the rest slots
  take_the_slot_with_fewest_successes(Slots, WordList, Successes, Slot, TheSlot,[],RestSlots),
  
  % pick the slot with fewest successes and fill it with a word
  fill_the_slot(TheSlot, WordList, [], NewWordList),
  
  fill(RestSlots, NewWordList).
============================================================================== 
%   count_successes(+Slot, +WordList, +SuccessesIn , −SuccessesOut) 
%   SuccessesIn: the importance of this term is to avoiding infinite loop,
%                as shown in github repo.
%   SuccessesOut: the output of number of succeses we want, was unified in
%                 the basecase

% Base Case
count_successes(_, [], SuccessesIn, SuccessesIn).

% Recursion to update SuccessesIn
count_successes(Slot, [W|Ws], SuccessesIn , SuccessesOut) :−
    ( can_fill(Slot, W)
    −> count_successes(Slot, Ws, SuccessesIn + 1, SuccessesOut) 
    ; count_successes(Slot, Ws, SuccessesIn, SuccessesOut)
    ).
% ==============================================================================
% can_fill(+Slot, +Word).
% can fill the Slot with Word 
can_fill([],[]). 
can_fill([Char1|Tail1],[Char2|Tail2]):−
    ( (Char1==Char2; var(Char1); var(Char2)) 
    −> can_fill(Tail1,Tail2)
    ).
% =============================================================================
% take_the_slot_with_fewest_successes(+Slots,
%                                     +WordList,
%                                     +Successes,
%                                     +PreSlot,
%                                     −TheSlot,
%                                     +RestSlotsIn,
%                                     −RestSlotsOut),

% Base Case, following the style of count_successes\2, unification the Input 
% to the Output
take_the_slot_with_fewest_successes([], _, FewestSuccesses, Slot, Slot,
                                    RestSlotsIn, RestSlotsIn):−
    % This ensures TheSlot has a match with at least A word 
    % This is a preassumption of fill_the_slot\2 predicate
    FewestSuccesses>0.

% Recursive Case
take_the_slot_with_fewest_successes([Slot|Slots], WordList, FewestSuccesses,
                                   PreSlot, TheSlot,
                  RestSlotsIn, RestSlotsOut) :−
    % count number of succeses of the first slot in Slots
    count_successes(Slot, WordList,0, Successes),
    ( Successes < FewestSuccesses
    −>  % Chuck the new TheSlot in, then update RestSlotsIn
        append(RestSlotsIn, [PreSlot], NewRestSlot), 
        take_the_slot_with_fewest_successes(Slots, WordList, Successes, Slot,
                                            TheSlot,
                                            NewRestSlot, RestSlotsOut)
    ;   % Keep the old TheSlot, and update RestSlotsIn
        append(RestSlotsIn, [Slot], NewRestSlot), 
        take_the_slot_with_fewest_successes(Slots, WordList,
                                        FewestSuccesses, PreSlot,
                                        TheSlot,
                                        NewRestSlot, RestSlotsOut)
% ==============================================================================
% fill_the_slot(+Slot, +WordList, +NewWordListIn, −NewWordListOut).
fill_the_slot(Slot,[Word|Words], L, NewWordList):−
  % end the predicate once can fill the slot
  % the match is guaranteed in recursive call
  % because the can_fill/2 when counting sucesses
  % take_the_slot_with_fewest_successes/7 ensures it
  % hence will not result in infinite loop without a base case
  Slot = Word, append(Words, L, NewWordList);
  % keep filling the slot, tail recursion
  append(L, [Word], L0), fill_the_slot(Slot, Words, L0, NewWordList).
% ==============================================================================