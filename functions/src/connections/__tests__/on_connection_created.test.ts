const mockUpdate = jest.fn().mockResolvedValue(undefined);
const mockGet = jest.fn();
const mockDoc = jest.fn().mockReturnValue({ update: mockUpdate, get: mockGet });
const mockAdd = jest.fn().mockResolvedValue(undefined);
const mockWhere = jest.fn();
const mockLimit = jest.fn();
const mockCollection = jest.fn().mockReturnValue({
  doc: mockDoc,
  add: mockAdd,
  where: mockWhere,
});
mockWhere.mockReturnValue({ limit: mockLimit });
mockLimit.mockReturnValue({ get: jest.fn() });

jest.mock('firebase-admin', () => ({
  initializeApp: jest.fn(),
  firestore: jest.fn().mockReturnValue({ collection: mockCollection }),
}));

jest.mock('firebase-admin/firestore', () => ({
  FieldValue: { serverTimestamp: jest.fn().mockReturnValue('SERVER_TIMESTAMP') },
  Timestamp: { now: jest.fn().mockReturnValue('TIMESTAMP_NOW') },
}));

import { onConnectionCreated } from '../on_connection_created';

/** Build a minimal DocumentSnapshot-like object understood by the function. */
function makeSnap(
  data: Record<string, unknown>,
  path: string,
) {
  const id = path.split('/').pop()!;
  return { id, data: () => data, ref: { path } };
}

describe('onConnectionCreated', () => {
  beforeEach(() => {
    mockUpdate.mockClear();
    mockGet.mockClear();
    mockDoc.mockClear();
    mockCollection.mockClear();
    mockAdd.mockClear();
    // parent user doc returned by get()
    mockGet.mockResolvedValue({ data: () => ({ firstName: 'Franck' }) });
  });

  it('generates inviteCode and updates the connection document', async () => {
    const snap = makeSnap(
      {
        parentId: 'uid-parent',
        inviteEmail: 'caregiver@example.com',
        inviteCode: null,
        message: null,
      },
      'connections/conn-1',
    );

    // Call the underlying handler directly
    await (onConnectionCreated as any).run(snap);

    expect(mockCollection).toHaveBeenCalledWith('connections');
    expect(mockDoc).toHaveBeenCalledWith('conn-1');
    expect(mockUpdate).toHaveBeenCalledWith(
      expect.objectContaining({
        inviteCode: expect.stringMatching(
          /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/,
        ),
      }),
    );
  });

  it('is idempotent — skips if inviteCode already set', async () => {
    const snap = makeSnap(
      {
        parentId: 'uid-parent',
        inviteEmail: 'x@x.com',
        inviteCode: 'already-set',
        message: null,
      },
      'connections/conn-2',
    );

    await (onConnectionCreated as any).run(snap);

    expect(mockUpdate).not.toHaveBeenCalled();
  });

  it('writes to /mail collection with correct email', async () => {
    const snap = makeSnap(
      {
        parentId: 'uid-parent',
        inviteEmail: 'caregiver@example.com',
        inviteCode: null,
        message: null,
      },
      'connections/conn-3',
    );

    await (onConnectionCreated as any).run(snap);

    expect(mockCollection).toHaveBeenCalledWith('mail');
    expect(mockAdd).toHaveBeenCalledWith(
      expect.objectContaining({
        to: 'caregiver@example.com',
        message: expect.objectContaining({
          subject: expect.stringContaining('Franck'),
          html: expect.stringContaining('/invite/'),
        }),
      }),
    );
  });
});
