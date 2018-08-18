// Assert that an error is thrown
export async function assertThrows(promise, err) {
    try {
        await promise;
        assert.isNotOk(true, err);
    } catch (e) {
        assert.include(e.message, 'VM Exception');
    }
}

export function paddy(string, padlen, padchar) {
    string = string.substr(0, 2) == '0x' ? string.slice(2) : string;
    var pad_char = typeof padchar !== 'undefined' ? padchar : '0';
    var pad = new Array(1 + padlen).join(pad_char);
    return (pad + string).slice(-pad.length);
}