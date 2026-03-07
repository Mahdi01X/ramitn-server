import { RoomService } from './room.service';
import { DEFAULT_CONFIG } from '@rami/shared';

describe('RoomService', () => {
  let service: RoomService;

  beforeEach(() => {
    service = new RoomService();
  });

  test('createRoom creates a room with code', () => {
    const room = service.createRoom('host1', 'Alice', {});
    expect(room.code).toBeDefined();
    expect(room.code.length).toBe(6);
    expect(room.hostId).toBe('host1');
    expect(room.players).toHaveLength(1);
    expect(room.players[0].name).toBe('Alice');
  });

  test('joinRoom adds player', () => {
    const room = service.createRoom('host1', 'Alice', {});
    const updated = service.joinRoom(room.code, 'p2', 'Bob');
    expect(updated.players).toHaveLength(2);
    expect(updated.players[1].name).toBe('Bob');
  });

  test('joinRoom rejects full room', () => {
    const room = service.createRoom('host1', 'Alice', { numPlayers: 2 });
    service.joinRoom(room.code, 'p2', 'Bob');
    expect(() => service.joinRoom(room.code, 'p3', 'Charlie')).toThrow('Room is full');
  });

  test('joinRoom rejects invalid code', () => {
    expect(() => service.joinRoom('INVALID', 'p1', 'Alice')).toThrow('Room not found');
  });

  test('leaveRoom removes player', () => {
    const room = service.createRoom('host1', 'Alice', {});
    service.joinRoom(room.code, 'p2', 'Bob');
    const updated = service.leaveRoom(room.id, 'p2');
    expect(updated!.players).toHaveLength(1);
  });

  test('leaveRoom transfers host', () => {
    const room = service.createRoom('host1', 'Alice', {});
    service.joinRoom(room.code, 'p2', 'Bob');
    const updated = service.leaveRoom(room.id, 'host1');
    expect(updated!.hostId).toBe('p2');
  });

  test('leaveRoom deletes empty room', () => {
    const room = service.createRoom('host1', 'Alice', {});
    const result = service.leaveRoom(room.id, 'host1');
    expect(result).toBeNull();
    expect(service.getRoom(room.id)).toBeUndefined();
  });

  test('setReady and allReady', () => {
    const room = service.createRoom('host1', 'Alice', {});
    service.joinRoom(room.code, 'p2', 'Bob');

    expect(service.allReady(room.id)).toBe(false);

    service.setReady(room.id, 'host1');
    expect(service.allReady(room.id)).toBe(false);

    service.setReady(room.id, 'p2');
    expect(service.allReady(room.id)).toBe(true);
  });

  test('findRoomByPlayer works', () => {
    const room = service.createRoom('host1', 'Alice', {});
    service.joinRoom(room.code, 'p2', 'Bob');

    expect(service.findRoomByPlayer('p2')?.id).toBe(room.id);
    expect(service.findRoomByPlayer('p3')).toBeUndefined();
  });

  test('matchmaking queues and matches players', () => {
    service.joinMatchmaking('p1', 'Alice', 's1', 2);
    const result1 = service.tryMatchmaking(2);
    expect(result1).toBeNull(); // Not enough players

    service.joinMatchmaking('p2', 'Bob', 's2', 2);
    const result2 = service.tryMatchmaking(2);
    expect(result2).not.toBeNull();
    expect(result2!.players).toHaveLength(2);
    expect(result2.room.players).toHaveLength(2);
  });
});

