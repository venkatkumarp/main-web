import { HighlightPipe } from './highlight.pipe';

describe('HighlightPipe', () => {
  let pipe: HighlightPipe;

  beforeEach(() => {
    pipe = new HighlightPipe();
  });

  it('should create an instance', () => {
    expect(pipe).toBeTruthy();
  });

  it('should highlight a single word', () => {
    const text = 'Hello World';
    const searchTerm = 'World';
    const result = pipe.transform(text, searchTerm);
    expect(result).toBe('Hello <b>World</b>');
  });

  it('should highlight multiple words', () => {
    const text = 'Angular is a great framework';
    const searchTerm = 'Angular great';
    const result = pipe.transform(text, searchTerm);
    expect(result).toBe('<b>Angular</b> is a <b>great</b> framework');
  });

  it('should highlight words with different cases', () => {
    const text = 'Hello World';
    const searchTerm = 'world';
    const result = pipe.transform(text, searchTerm);
    expect(result).toBe('Hello <b>World</b>');
  });

  it('should return original text when no match', () => {
    const text = 'Hello World';
    const searchTerm = 'Angular';
    const result = pipe.transform(text, searchTerm);
    expect(result).toBe('Hello World');
  });

  it('should return original text when search term is empty', () => {
    const text = 'Hello World';
    const searchTerm = '';
    const result = pipe.transform(text, searchTerm);
    expect(result).toBe('Hello World');
  });

  it('should return original text when text is empty', () => {
    const text = '';
    const searchTerm = 'Angular';
    const result = pipe.transform(text, searchTerm);
    expect(result).toBe('');
  });

  it('should handle special characters in search term', () => {
    const text = 'Hello (World)';
    const searchTerm = '(World)';
    const result = pipe.transform(text, searchTerm);
    expect(result).toBe('Hello <b>(World)</b>');
  });

  it('should handle multiple spaces in search term', () => {
    const text = 'Angular is great';
    const searchTerm = 'Angular   great';
    const result = pipe.transform(text, searchTerm);
    expect(result).toBe('<b>Angular</b> is <b>great</b>');
  });

  it('should highlight words at the beginning and end of the text', () => {
    const text = 'Hello World';
    const searchTerm = 'Hello World';
    const result = pipe.transform(text, searchTerm);
    expect(result).toBe('<b>Hello</b> <b>World</b>');
  });

  it('should highlight only the matched parts', () => {
    const text = 'Hello World, welcome to the World';
    const searchTerm = 'World';
    const result = pipe.transform(text, searchTerm);
    expect(result).toBe('Hello <b>World</b>, welcome to the <b>World</b>');
  });

  it('should highlight multiple occurrences of the same word', () => {
    const text = 'Test test test';
    const searchTerm = 'test';
    const result = pipe.transform(text, searchTerm);
    expect(result).toBe('<b>Test</b> <b>test</b> <b>test</b>');
  });

  it('should highlight words with punctuation', () => {
    const text = 'Hello, World! How are you?';
    const searchTerm = 'World';
    const result = pipe.transform(text, searchTerm);
    expect(result).toBe('Hello, <b>World</b>! How are you?');
  });
});