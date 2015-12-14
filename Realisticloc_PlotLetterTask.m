% plot the letter task depending on the specific moment of this task.

switch lower(TaskMoment)
    
    case lower('LetterPresentation')
        text = seq{k};
        [w, h] = RectSize(Screen('TextBounds', window, text));
        Screen('DrawText', window, text, round(crossX-w/2), round(crossY-h/2), colText);
        
    case lower('Blank')
        
    case lower('Fix')
        Screen('FillOval', window, colText, fix.pos);
        Screen('FillOval', window, bg, fix.posin);
end