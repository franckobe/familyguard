const mockSet = jest.fn().mockResolvedValue(undefined);
const mockDoc = jest.fn().mockReturnValue({ set: mockSet });
const mockCollection = jest.fn().mockReturnValue({ doc: mockDoc });

jest.mock('firebase-admin', () => ({
  initializeApp: jest.fn(),
  firestore: jest.fn().mockReturnValue({ collection: mockCollection }),
}));

jest.mock('firebase-admin/firestore', () => ({
  FieldValue: { serverTimestamp: jest.fn().mockReturnValue('SERVER_TIMESTAMP') },
}));

const testEnv = require('firebase-functions-test')();

import { onUserCreated } from '../on_user_created';

describe('onUserCreated', () => {
  beforeEach(() => {
    mockSet.mockClear();
    mockDoc.mockClear();
    mockCollection.mockClear();
  });

  afterAll(() => testEnv.cleanup());

  it('creates /users/{uid} document on new user', async () => {
    const wrapped = testEnv.wrap(onUserCreated);
    await wrapped({ uid: 'uid-abc', email: 'alice@example.com' });

    expect(mockCollection).toHaveBeenCalledWith('users');
    expect(mockDoc).toHaveBeenCalledWith('uid-abc');
    expect(mockSet).toHaveBeenCalledWith(
      expect.objectContaining({
        uid: 'uid-abc',
        email: 'alice@example.com',
        firstName: '',
        lastName: '',
        phone: null,
        avatarUrl: null,
        fcmToken: null,
      }),
    );
  });

  it('uses empty string when email is undefined', async () => {
    const wrapped = testEnv.wrap(onUserCreated);
    await wrapped({ uid: 'uid-no-email' });

    expect(mockSet).toHaveBeenCalledWith(
      expect.objectContaining({ email: '' }),
    );
  });
});
