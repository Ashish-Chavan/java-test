/**
 * ES2018 (ES9) Feature: RegExp Improvements
 * Named capture groups, lookbehind assertions, s (dotAll) flag,
 * Unicode property escapes \p{...}
 */
'use strict';

// ── Named capture groups (?<name>...) ──────────────────────────────────────
const datePattern = /(?<year>\d{4})-(?<month>\d{2})-(?<day>\d{2})/;

const match = '2024-03-15'.match(datePattern);
console.log(match.groups.year);    // 2024
console.log(match.groups.month);   // 03
console.log(match.groups.day);     // 15

// Destructuring named groups — the idiomatic pattern
const { groups: { year, month, day } } = 'Log entry 2023-11-28 status OK'.match(datePattern);
console.log(`year=${year}, month=${month}, day=${day}`);

// Named backreferences \k<name>
const duplicateWord = /\b(?<word>\w+)\s+\k<word>\b/;
console.log(duplicateWord.test('the the quick fox'));      // true
console.log(duplicateWord.test('the quick quick fox'));    // true
console.log(duplicateWord.test('the quick brown fox'));    // false

// Quoted string matcher with named backreference
const quoted = /(?<quote>["'])(?<content>.*?)\k<quote>/;
console.log('say "hello world" now'.match(quoted).groups);
console.log("say 'goodbye' now".match(quoted).groups);

// Named groups in replace with $<name>
const reformatted = '2024-03-15'.replace(datePattern, '$<day>/$<month>/$<year>');
console.log(reformatted);   // 15/03/2024

// Named groups in replace with function
const humanized = '2024-03-15'.replace(datePattern, (...args) => {
  const groups = args[args.length - 1];
  const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  return `${months[Number(groups.month) - 1]} ${Number(groups.day)}, ${groups.year}`;
});
console.log(humanized);

// ── Lookbehind assertions (?<=...) and (?<!...) ────────────────────────────
// Positive lookbehind: match only if preceded by pattern
const priceValue = /(?<=\$)\d+(\.\d+)?/;
console.log('Total: $42.99'.match(priceValue)[0]);      // 42.99 — without the $

const euroValue = /(?<=€)\d+/;
console.log('Price €150 today'.match(euroValue)[0]);

// Negative lookbehind: match only if NOT preceded by pattern
const notNegative = /(?<!-)\b\d+\b/g;
console.log('5 -3 12 -7 20'.match(notNegative));         // positive numbers only

// Lookbehind + lookahead combined: extract between markers
const betweenTags = /(?<=<title>).*?(?=<\/title>)/;
console.log('<title>My Page</title>'.match(betweenTags)[0]);

// Variable-length lookbehind (JS allows it, unlike many engines)
const afterGreeting = /(?<=(hello|hi|hey)\s)\w+/i;
console.log('Hello World'.match(afterGreeting)[0]);
console.log('hey Bob'.match(afterGreeting)[0]);

// ── s (dotAll) flag: . matches newlines ────────────────────────────────────
const multilineText = `first line
second line
third line`;

const withoutS = /first.*third/;
const withS    = /first.*third/s;

console.log(withoutS.test(multilineText));   // false — . stops at \n
console.log(withS.test(multilineText));      // true — dotAll

// dotAll flag introspection
console.log(withS.dotAll);                   // true
console.log(withS.flags);                    // 's'

// Practical: extracting multi-line blocks
const codeBlock = 'before ```const x = 1;\nconst y = 2;``` after';
const extract = /```(?<code>.*?)```/s;
console.log(codeBlock.match(extract).groups.code);

// ── Unicode property escapes \p{...} (requires u flag) ────────────────────
// Match by Unicode general category
const letters = /\p{Letter}+/gu;
console.log('Hello, Мир! 你好 123'.match(letters));      // all scripts

const numbers = /\p{Number}+/gu;
console.log('abc 123 ٤٥٦ Ⅷ'.match(numbers));            // includes Arabic-Indic, Roman

// Match by script
const greekOnly = /\p{Script=Greek}+/gu;
console.log('Mixed ελληνικά and English'.match(greekOnly));

const hanOnly = /\p{Script=Han}+/gu;
console.log('Text 中文字符 here'.match(hanOnly));

const cyrillicOnly = /\p{Script=Cyrillic}+/gu;
console.log('Привет world Москва'.match(cyrillicOnly));

// Negated property escape \P{...}
const nonLetters = /\P{Letter}+/gu;
console.log(JSON.stringify('ab12cd!@'.match(nonLetters)));

// Practical: emoji detection
const emojiPattern = /\p{Emoji_Presentation}/gu;
console.log('Hello 👋 World 🌍!'.match(emojiPattern));

// Practical: validate identifier-like strings across languages
const identifierPattern = /^[\p{Letter}_][\p{Letter}\p{Number}_]*$/u;
console.log(identifierPattern.test('variable1'));    // true
console.log(identifierPattern.test('переменная'));   // true — Cyrillic
console.log(identifierPattern.test('変数'));         // true — Japanese
console.log(identifierPattern.test('1invalid'));     // false

// ── Combining all four features ────────────────────────────────────────────
const logLine = `[2024-03-15] ERROR: Payment of $99.95 failed
Details: card declined`;

const logPattern = /(?<=\[)(?<date>\d{4}-\d{2}-\d{2})(?=\]).*?(?<level>\p{Lu}+):.*?\$(?<amount>[\d.]+).*?Details: (?<details>.*)/su;

const logMatch = logLine.match(logPattern);
console.log(logMatch.groups);
