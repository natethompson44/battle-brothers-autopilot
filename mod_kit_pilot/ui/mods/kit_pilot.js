// Kit Pilot: a "Kit up" button on the character (inventory) screen, and the report panel it opens.
var KitPilot = {};

KitPilot.CharacterScreen_createDIV = CharacterScreen.prototype.createDIV;
CharacterScreen.prototype.createDIV = function (_parentDiv)
{
    var result = KitPilot.CharacterScreen_createDIV.call(this, _parentDiv);
    var self = this;
    var host = this.mContainer || _parentDiv;

    var buttonContainer = $('<div class="kit-pilot-button-container"/>');
    this.mKitPilotButton = $('<div class="kit-pilot-button"/>').text('Kit up');
    this.mKitPilotButton.click(function () { self.kitPilotRun(); });
    buttonContainer.append(this.mKitPilotButton);
    host.append(buttonContainer);

    this.mKitPilotReport = $('<div class="kit-pilot-report kit-pilot-hidden"/>');
    host.append(this.mKitPilotReport);
    return result;
};

CharacterScreen.prototype.kitPilotRun = function ()
{
    var self = this;
    this.mKitPilotButton.addClass('kit-pilot-busy');
    SQ.call(this.mSQHandle, 'onKitPilot', null, function (_lines) {
        self.mKitPilotButton.removeClass('kit-pilot-busy');
        self.kitPilotShowReport(_lines);
    });
};

CharacterScreen.prototype.kitPilotShowReport = function (_lines)
{
    var panel = this.mKitPilotReport;
    var lines = _lines || [];
    panel.empty();

    var titleText = lines.length === 0 ? 'Kit Pilot: nothing to change'
        : 'Kit Pilot: ' + lines.length + ' change' + (lines.length === 1 ? '' : 's');
    panel.append($('<div class="kit-pilot-report-title"/>').text(titleText));

    var list = $('<div class="kit-pilot-report-list"/>');
    if (lines.length === 0) {
        list.append($('<div class="kit-pilot-report-line"/>').text('Everybody has the best the stash can offer for his role.'));
    }
    for (var i = 0; i < lines.length; i++) {
        list.append($('<div class="kit-pilot-report-line"/>').text(lines[i]));
    }
    panel.append(list);

    var close = $('<div class="kit-pilot-button kit-pilot-report-close"/>').text('Close');
    close.click(function () { panel.addClass('kit-pilot-hidden'); });
    panel.append(close);
    panel.removeClass('kit-pilot-hidden');
};
