const mockUpdate = jest.fn().mockResolvedValue(undefined);
const mockGet = jest.fn();
const mockDoc = jest.fn().mockReturnValue({ update: mockUpdate, get: mockGet });
const mockAdd = jest.fn().mockResolvedValue(undefined);

// Chainable where().limit().get() for querying connections
const mockCollectionGet = jest.fn();
const mockLimit = jest.fn().mockReturnValue({ get: mockCollectionGet });
const mockWhere = jest.fn().mockReturnValue({ limit: mockLimit });

const mockCollection = jest.fn().mockReturnValue({
  doc: mockDoc,
  add: mockAdd,
  where: mockWhere,
});

jest.mock('firebase-admin', () => ({
  initializeApp: jest.fn(),
  firestore: jest.fn().mockReturnValue({ collection: mockCollection }),
}));

jest.mock('firebase-admin/firestore', () => ({
  FieldValue: { serverTimestamp: jest.fn().mockReturnValue('SERVER_TIMESTAMP') },
  Timestamp: { now: jest.fn().mockReturnValue('TIMESTAMP_NOW') },
}));

import { getInviteDetails, acceptInvite } from '../accept_invite';

const makeContext = (uid?: string) => ({
  auth: uid ? { uid } : undefined,
  rawRequest: {} as any,
});

describe('getInviteDetails', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('returns parentFirstName, inviteEmail and status for a pending invite', async () => {
    // connections.where().limit().get() → one doc
    mockCollectionGet.mockResolvedValueOnce({
      empty: false,
      docs: [
        {
          id: 'conn-1',
          data: () => ({
            parentId: 'uid-parent',
            inviteEmail: 'caregiver@example.com',
            inviteCode: 'abc-123',
            status: 'pending',
            caregiverId: null,
          }),
        },
      ],
    });

    // users.doc(parentId).get() → parent profile
    mockGet.mockResolvedValueOnce({
      data: () => ({ firstName: 'Franck' }),
    });

    const result = await (getInviteDetails as any).run(
      { inviteCode: 'abc-123' },
      makeContext(),
    );

    expect(result).toEqual({
      parentFirstName: 'Franck',
      inviteEmail: 'caregiver@example.com',
      status: 'pending',
    });
  });

  it('throws not-found when inviteCode does not match', async () => {
    mockCollectionGet.mockResolvedValueOnce({ empty: true, docs: [] });

    await expect(
      (getInviteDetails as any).run({ inviteCode: 'no-such-code' }, makeContext()),
    ).rejects.toMatchObject({ code: 'not-found' });
  });

  it('throws an error containing already-used when status is not pending', async () => {
    mockCollectionGet.mockResolvedValueOnce({
      empty: false,
      docs: [
        {
          id: 'conn-2',
          data: () => ({
            parentId: 'uid-parent',
            inviteEmail: 'x@x.com',
            inviteCode: 'used-code',
            status: 'active',
            caregiverId: 'uid-caregiver',
          }),
        },
      ],
    });

    await expect(
      (getInviteDetails as any).run({ inviteCode: 'used-code' }, makeContext()),
    ).rejects.toMatchObject({ message: expect.stringContaining('already-used') });
  });
});

describe('acceptInvite', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('throws unauthenticated when called without auth', async () => {
    await expect(
      (acceptInvite as any).run({ inviteCode: 'abc-123' }, makeContext()),
    ).rejects.toMatchObject({ code: 'unauthenticated' });
  });

  it('updates caregiverId and status to active, returns connectionId', async () => {
    mockCollectionGet.mockResolvedValueOnce({
      empty: false,
      docs: [
        {
          id: 'conn-3',
          data: () => ({
            parentId: 'uid-parent',
            inviteEmail: 'caregiver@example.com',
            inviteCode: 'valid-code',
            status: 'pending',
            caregiverId: null,
          }),
        },
      ],
    });

    const result = await (acceptInvite as any).run(
      { inviteCode: 'valid-code' },
      makeContext('uid-caregiver'),
    );

    expect(result).toEqual({ connectionId: 'conn-3' });
    expect(mockCollection).toHaveBeenCalledWith('connections');
    expect(mockDoc).toHaveBeenCalledWith('conn-3');
    expect(mockUpdate).toHaveBeenCalledWith(
      expect.objectContaining({
        caregiverId: 'uid-caregiver',
        status: 'active',
      }),
    );
  });

  it('throws an error containing already-claimed when caregiverId is already set', async () => {
    mockCollectionGet.mockResolvedValueOnce({
      empty: false,
      docs: [
        {
          id: 'conn-4',
          data: () => ({
            parentId: 'uid-parent',
            inviteEmail: 'x@x.com',
            inviteCode: 'claimed-code',
            status: 'pending',
            caregiverId: 'uid-someone-else',
          }),
        },
      ],
    });

    await expect(
      (acceptInvite as any).run({ inviteCode: 'claimed-code' }, makeContext('uid-caregiver')),
    ).rejects.toMatchObject({ message: expect.stringContaining('already-claimed') });
  });
});
